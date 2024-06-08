The user code and user data lie in the pages beginning from the physical address 0x80001000 and 0x80002000 respectively.<br>
The page table is initialized with the mapping of virtual address 0x00000000 to the user level code section and 0x00001000 to the data section.<br>
Instruction page fault: Allot an available physical page and swap in the code. Assume every instruction page contains the same code as user code. Hence we have to copy the contents of the page beginning from 0x80001000 into the new physical page. <br>
Data page fault: Map the fault-generating virtual page to the physical page of the user data page starting from address 0x80002000. <br>
Handling the Level 0 page table entry indices dynamically in both the cases.<br>
