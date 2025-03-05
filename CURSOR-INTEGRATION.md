# AutoProgrammer - Cursor Integration

This feature allows AutoProgrammer to seamlessly integrate with Cursor, enabling you to use AutoProgrammer's outputs directly in your Cursor prompts.

## How It Works

1. AutoProgrammer now saves outputs to a dedicated folder (`cursor-output/`)
2. A "Save to Cursor" button appears in the AutoProgrammer UI after generating a response
3. Cursor can retrieve these outputs using the provided helper scripts

## Using the Integration

### In AutoProgrammer:

1. Start the AutoProgrammer desktop app: `cd autoprogrammer-desktop && npm start`
2. Ask a question and wait for a response
3. Click the "Save to Cursor" button that appears below the response
4. The output is now saved and ready for Cursor to use

### In Cursor:

To retrieve the latest output from AutoProgrammer, use the provided script:

```bash
./get-latest-for-cursor.sh
```

This will fetch the most recent output saved from AutoProgrammer and format it for easy use in your Cursor prompts.

You can copy the output directly into your Cursor prompt, or reference it as needed.

## File Structure

- `autoprogrammer-desktop/cursor-output/` - Directory where outputs are saved
- `autoprogrammer-desktop/cursor-agent-helper.js` - Helper script for formatting outputs
- `autoprogrammer-desktop/check-cursor-output.js` - Utility to manage saved outputs
- `get-latest-for-cursor.sh` - Convenient shell script to retrieve outputs

## Advanced Usage

The `check-cursor-output.js` script provides more advanced functionality:

- List all saved outputs: `node autoprogrammer-desktop/check-cursor-output.js list`
- Clear all saved outputs: `node autoprogrammer-desktop/check-cursor-output.js clear`
- Get the latest output: `node autoprogrammer-desktop/check-cursor-output.js get-latest`

## Troubleshooting

If you encounter issues with the Cursor integration:

1. Make sure AutoProgrammer desktop app is running
2. Verify that you've clicked the "Save to Cursor" button after generating a response
3. Check that the `cursor-output` directory exists in the `autoprogrammer-desktop` folder
4. Make sure the scripts have proper execute permissions (`chmod +x get-latest-for-cursor.sh`)

If the "Save to Cursor" button doesn't appear:
- The UI might need to be rebuilt. Try stopping and restarting the app. 