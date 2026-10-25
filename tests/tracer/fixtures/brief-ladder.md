---
lesson: tcp-handshake-ladder
goal: understand how the TCP three-way handshake opens a connection
sources: [topic]
level: novice
depth: working
budget: 10
modes: [text]
core: [SYN, SYN-ACK, ACK]
assumed: []
---
## Why
Preparing for a networking interview.

## Level evidence
define | What does a SYN do when a client opens a connection? | solid | defined correctly
why | Why does the server's reply, the SYN-ACK, carry two flags? | shaky | knew the flags, not the reason
apply | Trace the final ACK: what does it acknowledge and what can now flow? | missed | could not trace it
self-rating: intermediate (ladder says novice)
