# Brainfuck in Emacs Lisp

An educational Brainfuck interpreter written in Emacs Lisp, intended as a
vehicle for learning the Lisp language.

## Files

| File         | Description                                                        |
| ------------ | ------------------------------------------------------------------ |
| `bf.el`      | The interpreter. Loading it runs `M-x`-style `main`.               |
| `samples/`   | Sample Brainfuck programs.                                         |

## Usage

Requires Emacs 24+ (uses `pcase`). Created with Emacs 31.1.

In a running Emacs:

```
M-x load-file RET <path to bf.el> RET
```

`bf.el` evaluates `(main)` on load, which prompts for a `.bf` file in the
minibuffer (defaulting to `samples/`) and prints the program's output to
`*Messages*`.

## How it works

`main` drives a three-stage pipeline:

1. **Parse** — `char-to-op` maps each Brainfuck character to an instruction
   plist, e.g. `?+` → `(:kind :inc :operand 1)`; `parse-instructions`
   compiles the whole source into a vector of these, skipping non-opcodes.
2. **Resolve jumps** — `resolve-jumps` matches `[`/`]` pairs with a stack
   and patches each jump's operand so it points at its counterpart's index.
3. **Execute** — a fetch–decode–execute loop (`execute`) runs the program on
   a virtual "CPU", a hash table holding `"mem"` (a 1024-cell vector),
   `"PC"` (the program counter), and `"exe"` (the compiled program).

## Samples

| Program      | Output                                     |
| ------------ | ------------------------------------------ |
| `five.bf`    | `5`                                        |
| `hello.bf`   | `Hello World!` (from Wikipedia)            |
| `hello1.bf`  | `Hello, World!`                            |
| `hello2.bf`  | `Hello World!` (commented variant)         |
| `jumps.bf`   | Nested-loop exercise (prints a NUL byte)   |
| `quine.bf`   | Its own source code                        |
| `cat.bf`     | (cannot run, see below)                    |

## Limitations

- `,` (read a byte) is not implemented — executing it errors, which is why
  `cat.bf` does not work.
- Memory cells are full Lisp integers; there is no 8-bit wrap-around.
- `my/read-file` takes a `filename` argument but actually reads the global
  `source-name` that `main` sets.
