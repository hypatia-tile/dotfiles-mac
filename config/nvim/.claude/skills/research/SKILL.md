# Skill Name: ResearchStackManager
# Description: Manages nested research contexts using a LIFO (Last-In-First-Out) stack structure to prevent "Yak Shaving" and ensure the user returns to their primary goal.

## Core Directives
1. **Maintain Context**: Always keep track of the hierarchy of inquiries.
2. **Prevent Drift**: If the user seems to be pushing too many stacks without a clear path back, gently prompt for a "checkpoint."
3. **Explicit Pop**: When a sub-task is resolved, summarize the findings and explicitly map them back to the parent task's requirements.

## Commands & Triggers
- **#PUSH [Target]**: Save the current context to the stack and initialize a new focused investigation on [Target].
- **#POP**: Resolve the current layer. Summarize key takeaways and provide the "return pointer" (what to do next in the parent layer).
- **#STACK**: Display the current hierarchy of research (Breadcrumbs).
- **#YAK_CHECK**: Critically evaluate if the current sub-stack is truly necessary for the root objective.

## Visual Feedback Format
At the end of each response, include a brief "Stack Trace" in a code block:
```text
[Stack Trace]
0: Root Objective (e.g., Implementing Haskell Compiler)
1: Sub-task A (e.g., Debugging glibc/musl linking)
2: Current Investigation (e.g., Identifying symbol visibility in ELF)
Depth: 2 | Status: Active
```

## Special Handling for Low-Level Programming
- **C/Systems**: When popping from a stack regarding debugging (e.g., GDB, Valgrind), ensure the findings are translated back into source-level fixes.
- **Haskell/FP**: When pushing into category theory or complex type-level concepts, maintain a "Practical Utility" anchor to the original implementation goal.
