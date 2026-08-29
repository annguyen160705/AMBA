# What is bus
![alt text](image-5.png)
Bus means a set of commoon lines that electrically connects various blocks in order to transfer data among them.

# Bus arbitration
![alt text](image-6.png)

## Algorithm of arbitration
Fixed priority based
Round-robin

## Issues of arbitration
### Starvation
![alt text](image-8.png)

Starvation is a situation in bus arbitration where a block is unable to gain bus access and make progress for an extended period. As you can see REQ4 is starving, waiting for signal.
### Fairness
![alt text](image-7.png)

Fairness is an arbitration mechanism designed to prevent the starvation of lower-priority devices by grouping bus access into structured "rounds."


### Live-lock
![alt text](image-9.png)

Live-lock is a condition where a hardware block is actively busy performing operations but is unable to make any actual progress. Unlike a dead-lock, a live-lock will eventually be resolved.



### Deadlock

Dead-lock is a situation in bus arbitration where a hardware block waits indefinitely for a condition that will never be resolved.

![alt text](image-10.png)

Master 0 cannot proceed to Slave Y because the arbiter on Bus B is currently locked by Master 3. Conversely, Master 3 cannot proceed to Slave X because the arbiter on Bus A is currently locked by Master 0.

Both masters (0 and 3) are stuck indefinitely, each holding the resource the other needs while waiting for the other to release its bus.

# Transfer types