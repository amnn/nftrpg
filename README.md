# NFTRPG

A slightly larger demo of features, (standard) libraries and
programming patterns (listed below) in Sui Move, with the theme of an
RPG that stores avatars, shops and weapons on-chain.

## Examples In this Demo

### Language Features
- Abilities (copy, drop, key, store)
- Asserts, aborts and error codes
- Constants
- Events
- Functions (entry functions, library functions and private functions)
- Generics (including phantom types)
- Module Initializers
- Objects (owned and shared)
- References
- Structs
- Vectors

### Patterns
- Capabilities
- Hot Potato
- Marker types
- One-time witness
- Witness pattern

### Standard Libraries
- `std::option` -- Options
- `std::string` -- Strings (built on top of vectors)
- `sui::coin`, `sui::balance` -- Generic Token API
- `sui::dynamic_field` -- Dynamic fields 
- `sui::dynamic_object_field` -- dynamic object fields
- `sui::transfer` -- Transferring and sharing

## Dependencies

To run this demo, you will need a recent (0.13+) version of Sui
installed -- it has been tested with 0.15.
