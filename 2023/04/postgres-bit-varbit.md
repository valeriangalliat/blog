# Postgres casting to `bit` vs. `varbit` vs. `"bit"` (with quotes)
April 5, 2023

Here's a few things to know if you're working with bit strings in
Postgres.

## `bit` means `bit(1)`

As documented [here](https://www.postgresql.org/docs/8.0/functions-bitstring.html),
`bit` is an alias for `bit(1)`, so it will only keep the least
significant bit.

```
42::bit(10)  0000101010
42::bit(1)            0
42::bit               0

43::bit(10)  0000101011
43::bit(1)            1
43::bit               1
```

## Define bit strings with `B'101010'`

You can define bit strings with the `B` prefix:

```
B'101010'             101010
B'101010'::int        42
pg_typeof(B'101010')  bit
```

## Cast a string to `bit`

If you have a string made of only 0s and 1s, you can cast it to a bit
string too! Useful for dynamically generating bit sequences.

```
'101010'::bit(10)  1010100000
```

But we instantly notice an interesting difference: when casting from an
integer as we did earlier, the truncation (or padding otherwise) was
right-aligned, while when casting from a string, it's left-aligned.

```
12::bit(4)       1100
12::bit(2)         00
'1100'::bit(4)   1100
'1100'::bit(2)   11
B'1100'::bit(2)  11
```

## Dynamic length bit strings

What if you're generating a bit string from... an actual string, but you
don't know its length in advance? You can always use a fixed length
that's larger than what you think you'll need, but that may not be very
efficient.

Instead, you can use the `bit varying` type, also known as `varbit`!

```
'101010'::bit varying             101010
'101010'::varbit                  101010
pg_typeof('101010'::bit varying)  bit varying
pg_typeof('101010'::varbit)       bit varying
```

Alternatively, there's an [internal, undocumented `"bit"` type](https://dba.stackexchange.com/a/204838/240451)
(to not be mistaken with `bit` without the quotes), which will
automatically cast to a static-sized `bit`, _but inferring the size form
the input_!

```
'101010'::bit                1
'101010'::varbit             101010
pg_typeof('101010'::varbit)  bit varying
'101010'::"bit"              101010
pg_typeof('101010'::"bit")   bit
```

<div class="note">

**Note:** there's probably very little situations where you'd need
`"bit"` instead of `varbit`, but at least now you know it exists. I
wouldn't recommend relying on a type that's internal to Postgres and
undocumented though!

</div>

The `"bit"` magic is not transparent to [`\gdesc`](https://www.postgresql.org/docs/current/app-psql.html)
though:

```
'101010'::bit     1       bit(1)
'101010'::bit(6)  101010  bit(6)
'101010'::varbit  101010  bit varying
'101010'::"bit"   101010  "bit"
```



