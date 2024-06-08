
.section .text
.global main

main:
    # Prepare jump to super mode
    li t1, 1
    slli t1, t1, 11   #mpp_mask
    csrs mstatus, t1
    
    la t4, supervisor       #load address of user-space code
    csrrw zero, mepc, t4    #set mepc to user code
    
    la t5, page_fault_handler
    csrw mtvec, t5
   
    mret

supervisor:
################## Setting up page tables ##############
    # Set value in PTE2 (Initial Mapping)
    li a0,0x81000000
    li a1, 0x82000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 16(a0)

    # To set V.A 0x0 -> P.A 0x0
    li a1, 0x82001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE1 (Initial Mapping)
    li a0,0x82000000
    li a1, 0x83000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set Frame number in PTE0 (Initial Mapping)
    li a0,0x83000000
    li a1, 0x80000
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 0(a0)

    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 8(a0)

    # Set value in PTE1 (Code Mapping)
    li a0,0x82001000
    li a1, 0x83001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE0 (Code Mapping)
    li a0,0x83001000
    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xfb # D | A | G | U | X | - | R |V
    sd a1, 0(a0)

    # Data Mapping
    li a1, 0x80002
    slli a1, a1, 0xa
    ori a1, a1, 0xf7 # D | A | G | U | - | W | R |V
    sd a1, 8(a0)
    

####################################################################

    # Prepare jump to user mode
    li t1, 0
    slli t1, t1, 8   #spp_mask
    csrs sstatus, t1

    # Configure satp
    la t1, satp_config 
    ld t2, 0(t1)
    sfence.vma zero, zero
    csrrw zero, satp, t2
    sfence.vma zero, zero

    li t4, 0       # load VA address of user-space code
    csrrw zero, sepc, t4    # set sepc to user code
    
    sret

###################################################################
##################### ADD CODE ONLY HERE  #########################
###################################################################
.align 4
page_fault_handler:
    csrr s1, mcause
    li s2, 12;
    # if mcause==12, it is instr handlerj
    bne s1,s2,data_handler

    #handling instructions
    #a1 holds the new page pointer
    li a1, 0x80003000

    # eg, if varcount==1, new page starts from 80003000 and goes on till 80004000-8
    la s2,var_count
    lw s2,0(s2)
    slli s2, s2, 12
    add a1,a1,s2

    li a0, 0x80002000
    li a3,0x1000
    #a0 holds pointer to user code page
    #a1 holds the new page pointer

    loop:
        addi a0,a0,-8
        addi a1,a1,-8
        addi a3,a3,-8

        #hold value to copy in a4
        ld a4,0(a0)
        #store in a1
        sd a4,0(a1)
        bnez a3,loop

    srli a1, a1, 2 # >> 12 and << 10
    ori a1,a1, 0xfb # D | A | G | U | X | - | R |V
    csrr a2, mtval
    srli a2,a2,9
    li a0, 0x83001000
    add a0,a0,a2
    sd a1,0(a0)
    #mapping
    mret

data_handler:
    li a0, 0x80002
    csrr a1, mtval
    srli a1,a1,9
    li a2, 0x83001000
    slli a0,a0,10
    ori a0,a0,0xf7 # D | A | G | U | - | W | R |V
    add a2,a2,a1
    #mapping
    sd a0,0(a2)
    mret

###################################################################
###################################################################

.align 12
user_code:
    la t1,var_count
    lw t2, 0(t1)
    addi t2, t2, 1
    sw t2, 0(t1)

    la t5, code_jump_position
    lw t3, 0(t5)
    li t4, 0x2000
    add t3, t3, t4
    sw t3, 0(t5)
    
    jalr x0, t3

.data
.align 12
var_count:  .word  0
code_jump_position: .word 0x0000

.align 8
# Value to set in satp
satp_config: .dword 0x8000000000081000
