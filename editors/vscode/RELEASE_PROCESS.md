# Release Process

1. Bump up the version on `package.json`
2. [Publish the extension](https://code.visualstudio.com/api/working-with-extensions/publishing-extension).

```bash
npm install -g @vscode/vsce
vsce package
vsce publish --pat $MICROSOFT_VSCODE_API_KEY
```
