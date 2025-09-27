// JavaScript Examples for nvim-stringbreaker Plugin Testing
// This file contains various string examples to test the plugin functionality

const config = {
  name: 'nvim-stringbreaker',
  version: '1.0.0',
  description: 'A Neovim plugin for breaking long strings into multiple lines',
  author: 'Your Name',
  license: 'MIT',
};

// Example 1: Long string with single quotes
const longSingleQuote =
  "This is a very long string that contains multiple sentences and should be broken into multiple lines for better readability. The string includes various punctuation marks like periods, commas, and exclamation marks! It also contains special characters such as @, #, $, %, ^, &, *, (, ), _, +, -, =, [, ], {, }, |, ;, :, \", ', <, >, ?, and /. This string is designed to test the nvim-stringbreaker plugin's ability to handle long text content and properly format it across multiple lines.";

// Example 2: Long string with double quotes
const longDoubleQuote =
  'This is another very long string that demonstrates the plugin\'s ability to handle double-quoted strings. It contains multiple paragraphs of text that would benefit from being split across multiple lines. The string includes various types of content: regular text, numbers like 123 and 456, special characters like !@#$%^&*(), and even some escaped characters like "quotes" and \\backslashes\\. This comprehensive example should thoroughly test the string breaking functionality.';

// Example 3: String with mixed quotes and escapes
const mixedQuotes =
  "This string contains 'single quotes' and \"double quotes\" along with various escape sequences like \\n for newlines, \\t for tabs, \\r for carriage returns, and \\\\ for backslashes. It also includes unicode characters like \u{1F600} (smiling face) and \u{1F4BB} (laptop). The string is designed to test the plugin's handling of complex escape sequences and special characters.";

// Example 4: Template string with embedded expressions
const templateString = `This is a template string that demonstrates the plugin's ability to handle template literals with embedded expressions. The current date is ${new Date().toLocaleDateString()} and the current time is ${new Date().toLocaleTimeString()}. This string contains multiple lines and should be properly formatted. It includes various content types: regular text, numbers like ${Math.PI.toFixed(
  2
)}, and even function calls like ${Math.random().toFixed(
  4
)}. The template string syntax allows for complex string interpolation and multi-line content.`;

// Example 5: String with complex formatting
const complexFormatting =
  'This string contains complex formatting elements including:\n1. Numbered lists with items\n2. Code snippets like \'function example() { return true; }\'\n3. File paths like /usr/local/bin/example\n4. URLs like https://www.example.com/path?param=value&other=123\n5. JSON-like structures: {"key": "value", "number": 42}\n6. Regular expressions: /^[a-zA-Z0-9]+$/\n7. SQL queries: SELECT * FROM users WHERE id = 1\n8. HTML tags: <div class="container">content</div>\nThis comprehensive example tests various formatting scenarios.';

// Example 6: String with nested quotes
const nestedQuotes =
  "This string demonstrates nested quote handling with \"double quotes inside single quotes\" and 'single quotes inside double quotes'. It also includes escaped quotes like \\\"escaped double\\\" and \\'escaped single\\'. The string contains various combinations: \"mixed 'nested' quotes\" and 'mixed \"nested\" quotes'. This tests the plugin's ability to properly handle quote nesting and escaping.";

// Example 7: String with code-like content
const codeLikeContent =
  "This string contains code-like content that should be properly formatted:\n\nfunction calculateTotal(items) {\n  let total = 0;\n  for (let item of items) {\n    if (item.price && item.quantity) {\n      total += item.price * item.quantity;\n    }\n  }\n  return total;\n}\n\nconst result = calculateTotal([\n  { name: 'Apple', price: 1.50, quantity: 3 },\n  { name: 'Banana', price: 0.75, quantity: 5 },\n  { name: 'Orange', price: 2.00, quantity: 2 }\n]);\n\nconsole.log('Total:', result);";

// Example 8: String with error messages
const errorMessages =
  "Error handling examples:\n\n1. Validation Error: 'The input data does not meet the required criteria. Please check your input and try again.'\n2. Network Error: \"Network connection failed. Please check your internet connection and try again later.\"\n3. Permission Error: 'Access denied. You do not have sufficient permissions to perform this action.'\n4. File Not Found: \"The specified file could not be found. Please verify the file path and ensure the file exists.\"\n5. Invalid Format: 'The file format is not supported. Please use a supported file format and try again.'";

// Example 9: String with configuration data
const configData =
  'Configuration options for the plugin:\n\n{\n  "preview": {\n    "max_length": 1000,\n    "use_float": true,\n    "width": 80,\n    "height": 20\n  },\n  "keybindings": {\n    "break_string": "<space>fes",\n    "preview": "<space>fep",\n    "save": "<space>fs",\n    "cancel": "<space>qq"\n  },\n  "filetypes": [\n    "lua",\n    "javascript",\n    "python",\n    "json",\n    "yaml"\n  ]\n}';

// Example 10: String with documentation
const documentation =
  "nvim-stringbreaker Plugin Documentation\n\n## Overview\nThis Neovim plugin provides functionality to break long strings into multiple lines for better readability and code maintenance.\n\n## Features\n- Automatic string detection using Tree-sitter\n- Support for multiple programming languages\n- Visual mode text selection\n- Preview functionality\n- Configurable keybindings\n\n## Installation\nUse your preferred plugin manager:\n\n### Packer\n```lua\nuse {\n  'your-username/nvim-stringbreaker',\n  requires = { 'nvim-treesitter/nvim-treesitter' }\n}\n```\n\n### Lazy.nvim\n```lua\n{\n  'your-username/nvim-stringbreaker',\n  dependencies = { 'nvim-treesitter/nvim-treesitter' }\n}\n```\n\n## Usage\n1. Place cursor inside a string or select text in visual mode\n2. Use the configured keybinding to break the string\n3. Edit the content in the opened buffer\n4. Save changes or cancel editing\n\n## Configuration\nSee the configuration section for available options and customization.";

// Example 11: String with regular expressions
const regexExamples =
  'Regular expression examples:\n\n1. Email validation: /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/\n2. Phone number: /^\\+?[\\d\\s\\-\\(\\)]+$/\n3. URL validation: /^https?:\\/\\/[\\w\\-]+(\\.[\\w\\-]+)+([\\w\\-\\.,@?^=%&:\\/~\\+#]*[\\w\\-\\@?^=%&\\/~\\+#])?$/\n4. IPv4 address: /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/\n5. Strong password: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$/';

// Example 12: String with API documentation
const apiDocumentation =
  'API Documentation Example:\n\n## User Management API\n\n### Create User\n**Endpoint**: POST /api/users\n**Description**: Creates a new user account\n\n**Request Body**:\n```json\n{\n  "username": "johndoe",\n  "email": "john@example.com",\n  "password": "securePassword123",\n  "profile": {\n    "firstName": "John",\n    "lastName": "Doe",\n    "bio": "Software developer with 5+ years of experience"\n  }\n}\n```\n\n**Response**:\n```json\n{\n  "success": true,\n  "data": {\n    "id": 123,\n    "username": "johndoe",\n    "email": "john@example.com",\n    "createdAt": "2024-01-15T10:30:00Z"\n  }\n}\n```\n\n**Error Responses**:\n- 400: Bad Request - Invalid input data\n- 409: Conflict - Username or email already exists\n- 500: Internal Server Error - Server error occurred';

// Function to demonstrate string usage
function demonstrateStrings() {
  console.log('JavaScript string examples loaded successfully!');
  console.log('String lengths:');
  console.log(`- longSingleQuote: ${longSingleQuote.length} characters`);
  console.log(`- longDoubleQuote: ${longDoubleQuote.length} characters`);
  console.log(`- mixedQuotes: ${mixedQuotes.length} characters`);
  console.log(`- templateString: ${templateString.length} characters`);
  console.log(`- complexFormatting: ${complexFormatting.length} characters`);
  console.log(`- documentation: ${documentation.length} characters`);
  console.log(`- regexExamples: ${regexExamples.length} characters`);
  console.log(`- apiDocumentation: ${apiDocumentation.length} characters`);
}

// Some text test
// Test double quote "This is double quote"

// Call the demonstration function
demonstrateStrings();
