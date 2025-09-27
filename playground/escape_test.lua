-- Test file for StringEscape and StringUnescape commands
-- This file contains various string examples to test the new escape/unescape functionality

-- Simple docs to test escpae of, for example 'quote', 'escape' \a , "double quote"

-- Double quoted strings with various escape sequences
local double_quote_examples = {
  -- Basic string
  simple = "Hello World",

  -- String with newlines and tabs
  with_escapes = "Line 1\nLine 2\tTabbed",

  -- String with quotes
  with_quotes = "He said \"Hello\" to me",

  -- Mixed content
  mixed = "Path: C:\\Users\\Name\nMessage: \"Welcome!\"",

  -- Already escaped content (for testing unescape)
  already_escaped = "Line 1\\nLine 2\\tTabbed\\\"Quote\\\"",
}

-- Single quoted strings
local single_quote_examples = {
  simple = 'Hello World',
  with_escapes = 'Line\'s 1\nLine 2\tTabbed',
  with_quotes = 'He said \'Hello\' to me',
  mixed = 'Path: C:\\Users\\Name\nMessage: \'Welcome!\'',
}

-- Test strings for visual selection
local test_content = [[
This is a test string with
multiple lines and some special characters:
	- Tab character
	- "Double quotes"
	- 'Single quotes'
	- Backslash: \
]]

-- Usage instructions:
--[[
To test the new commands:

1. Place cursor inside any string above and run:
   :StringEscape single    (or :StringEscape double)
   :StringUnescape

2. Select text in visual mode and run:
   :StringEscape single
   :StringEscape double
   :StringUnescape

3. Test with ranges:
   :1,5StringEscape double
   :1,5StringUnescape

The commands should work with both normal mode (cursor inside string)
and visual mode (selected text).
]]

return {
  double_quote_examples = double_quote_examples,
  single_quote_examples = single_quote_examples,
  test_content = test_content,
}

