# Bundle Lambda function with private dependencies using CDK
April 12, 2021

I use [CDK] to deploy AWS resources, and one of the challenges I've had
recently was to deploy Lambda functions that have external dependencies.

The functions I want to deploy are written in Python, and CDK
conveniently provides the [`aws-lambda-python`] module and its
`PythonFunction` construct which knows how to install dependencies from
`requirements.txt` out of the box, but this doesn't work for my case as
it doesn't support customizing the Docker command used to bundle the
Lambda function.

In particular, I need to install dependencies from private repositories
which requires some credentials to be present in the container.

[CDK]: https://aws.amazon.com/cdk/
[`aws-lambda-python`]: https://docs.aws.amazon.com/cdk/api/latest/docs/aws-lambda-python-readme.html

## CDK Lambda asset bundling

Instead, CDK offers a way to write custom bundling logic for Lambda
functions (which is what `PythonFunction` uses internally); from their [documentation]:

[documentation]: https://docs.aws.amazon.com/cdk/api/latest/docs/aws-lambda-readme.html#bundling-asset-code

```js
new lambda.Function(this, 'Function', {
  code: lambda.Code.fromAsset(path.join(__dirname, 'my-python-handler'), {
    bundling: {
      image: lambda.Runtime.PYTHON_3_8.bundlingImage,
      command: ['bash', '-c', 'pip install -r requirements.txt -t /asset-output && cp -a . /asset-output']
    }
  }),
  runtime: lambda.Runtime.PYTHON_3_8,
  handler: 'index.handler'
})
```

The `bundling` options give us a [number of parameters] to customize the
Docker container that bundles the Lambda asset, like `environment` to
pass credentials in environment variables, or `volumes` which can be
used to mount directories or even single files that contains credentials
or other data you would want inside the bundling container, e.g.:

```js
new lambda.Function(this, 'Function', {
  code: lambda.Code.fromAsset(path.join(__dirname, 'my-python-handler'), {
    bundling: {
      image: lambda.Runtime.PYTHON_3_8.bundlingImage,
      command: ['bash', '-c', 'pip install -r requirements.txt -t /asset-output && cp -a . /asset-output'],
      environment: {
        SECRET: 'token'
      },
      volumes: [
        {
          containerPath: '/.secret',
          hostPath: `${process.env.HOME}/.secret`
        }
      ]
    }
  }),
  runtime: lambda.Runtime.PYTHON_3_8,
  handler: 'index.handler'
})
```

[number of parameters]: https://docs.aws.amazon.com/cdk/api/latest/docs/@aws-cdk_core.BundlingOptions.html

This works, at least on my Linux machine, but the `pip install` command
failed on macOS with the following error:

```
ERROR: Exception:
Traceback (most recent call last):
 File "/var/lang/lib/python3.8/shutil.py", line 791, in move
  os.rename(src, real_dst)
OSError: [Errno 18] Invalid cross-device link: '/tmp/.../dulwich' -> '/asset-output/dulwich'

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
 File "/var/lang/lib/python3.8/site-packages/pip/_internal/cli/base_command.py", line 228, in _main
  status = self.run(options, args)
 File "/var/lang/lib/python3.8/site-packages/pip/_internal/cli/req_command.py", line 182, in wrapper
  return func(self, options, args)
 File "/var/lang/lib/python3.8/site-packages/pip/_internal/commands/install.py", line 455, in run
  self._handle_target_dir(
 File "/var/lang/lib/python3.8/site-packages/pip/_internal/commands/install.py", line 512, in _handle_target_dir
  shutil.move(
 File "/var/lang/lib/python3.8/shutil.py", line 801, in move
  copytree(src, real_dst, copy_function=copy_function,
 File "/var/lang/lib/python3.8/shutil.py", line 557, in copytree
  return _copytree(entries=entries, src=src, dst=dst, symlinks=symlinks,
 File "/var/lang/lib/python3.8/shutil.py", line 513, in _copytree
  raise Error(errors)
shutil.Error: [('/tmp/.../test_porcelain.py', '/asset-output/.../test_porcelain.py', '[Errno 5] Input/output error')]
```

This is especially confusing as searching for `OSError: [Errno 18] Invalid cross-device link`
often results in answers recommending to use `shutil.move` instead of
`os.rename`, but we can see in the stack trace that `os.rename` was
invoked *by* `shutil.move`!

But if we look at the implementation of `shutil.move`, we can see that
the way they support cross fileystem copy is by letting the `OSError`
exception happen and handling it. This makes it more obvious that our
actual issue is the exception that happened during the exception
handling (`[Errno 5] Input/output error`)

It seems that even with their filesystem resilient implementation, we
still get some IO error when using Docker on macOS.

## The fix

To mitigate that, I modified the suggested command slightly so that we
install the dependencies in `/tmp` which is won't require pip to do any
cross filesystem operations, and then add that to the `cp` command we
already have.

I also like to replace the hardcoded `/asset-output` by the constant
`cdk.AssetStaging.BUNDLING_OUTPUT_DIR`.

```js
new lambda.Function(this, 'Function', {
  code: lambda.Code.fromAsset(path.join(__dirname, 'my-python-handler'), {
    bundling: {
      image: lambda.Runtime.PYTHON_3_8.bundlingImage,
      command: ['bash', '-c', `pip install -r requirements.txt -t /tmp/deps && cp -a . /tmp/deps/* ${cdk.AssetStaging.BUNDLING_OUTPUT_DIR}`],
      environment: {
        SECRET: 'token'
      },
      volumes: [
        {
          containerPath: '/.secret',
          hostPath: `${process.env.HOME}/.secret`
        }
      ]
    }
  }),
  runtime: lambda.Runtime.PYTHON_3_8,
  handler: 'index.handler'
})
```

Hope this helps!
