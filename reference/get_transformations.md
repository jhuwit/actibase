# Get Transformations

Get Transformations

## Usage

``` r
get_transformations(data)

prefix_transformations(transformations, prefix = NULL)

set_transformations(data, transformations, add = TRUE, prefix = NULL)
```

## Arguments

- data:

  data set of data, usually time and X/Y/Z.

- transformations:

  character string of transformations

- prefix:

  if not \`NULL\`, the prefix plus \`:\` would be pasted to the
  transformations.

- add:

  Add the transformations to those already there in \`data\`

## Value

`set_transformations` returns the data, with the \`transformations\`
attribute updated and `set_transformations` returns the attribute
\`transformations\`
