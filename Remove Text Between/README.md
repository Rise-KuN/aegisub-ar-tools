# Remove Text Between

- Remove Text Between Characters/Words.

## Examples

- You can use characters or words and symbols and it supports arabic too.

- if the Remove Char is set to `false` it will keep the `start_char` and `end_char`.

- You can delete the `start_char` only by keeping the `end_char` empty.

- Input: `Hello From World`, Start Char: `H`, End Char: `m`, Remove Char: `True`, Result: ` World`.

- Input: `Hello From Moon`, Start Char: `H`, End Char: `o`, Remove Char: `False`, Result: `Hrom Moon`.

- Input: `Hello From Sky`, Start Char: ` From`, End Char: ` `, Remove Char: `True`, Result: `Hello Sky`.