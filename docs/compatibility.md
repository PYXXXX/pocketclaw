# Compatibility

PocketClaw is designed to work with the OpenClaw Gateway **as it exists today**.

## Hard constraints

- no Gateway modifications
- no private patches
- no custom backend
- no reliance on undocumented storage mutations

## Compatibility stance

PocketClaw should adapt to the currently exposed Gateway surface rather than assuming future APIs will appear.

## Practical implications

- client-controlled session creation through `sessionKey`
- adapter-based wrapping of current Gateway methods
- conservative handling of protocol and payload differences
