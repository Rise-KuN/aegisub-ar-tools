# Copy & Paste Tags

Copy the first override-tag block from selected subtitle lines, then paste those tags onto another selection.

## Usage

1. Select the lines to copy tags from and run **Copy and Paste Tags**.
2. Choose **Copy Tags**.
3. Select the destination lines and run the macro again.
4. Choose **Paste Tags**.

The macro processes lines in selection order. The source and destination selections must contain the same number of lines. On paste, the first override-tag block at the start of each line is replaced; if a line has no leading override-tag block, the copied tags are inserted at the beginning of its text.

If a source line has no leading override-tag block, it is copied as an empty `{}` block.
