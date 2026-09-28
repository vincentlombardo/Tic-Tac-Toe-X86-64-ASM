# Vincent Lombardo
#as -o tic.o tic.s
#ld tic.o -o tic
#./tic

.section .data
msg:
.string "Hello, world!\n"

t1:
.string " 8 | 7 | 6\n---+---+---\n 5 | 4 | 3\n---+---+---\n 2 | 1 | 0" # len 57

e:
.string " " # len 1

gap: 
.string " | " # len 3

divider:
.string "\n---+---+---\n" #13

buffer:
.space 5          # reserve 128 bytes for input

prompt:
.string "\nEnter 0-8 For Your Move: " #25
iprompt:
.string "\nCannot Move Here. Enter 0-9 For Your Move: " #43


p1:
.string "X"

p1win:
.string "X Wins\n" #7

p2:
.string "#"

p2win:
.string "# Wins\n" #7

ln:
.string "\n---------------------\n" #23

.section .text
.globl _start

_start:
mov $0, %r8 # init board register r8
mov $0, %r9 # turn register
mov $0, %rcx # Holds the ending value
mov $0, %r10 # Gonna hold the ending value if it gets overwritten
mov $0, %r11 # end register
mov $0, %r12 # bitmask register

# RCX Gonna hold the value
## -- do this on turn mov $35, %r10  # 35 -> #  64 -> @     r10 is gonna be current char register
lea t1(%rip), %rsi
mov $56, %rdx
call prnt

jmp promptf
printe:
	lea e(%rip), %rsi
	mov $1, %rdx
	call prnt
	ret
printv:
	#if statment
	cmp $0, %r9
	jne sk1
		lea p1(%rip), %rsi 
		jmp post
	sk1:
		lea p2(%rip), %rsi 
	post:
		mov $1, %rax
		mov $1, %rdi 
		mov $1, %rdx
		syscall

printgap:
	lea gap(%rip), %rsi 
	mov $3, %rdx
	call prnt
	ret
printdiv:
	lea divider(%rip), %rsi
	mov $13, %rdx
	call prnt
	ret
prnt:
	### In order to use, set rsi and rdx
	mov $1, %rax        # syscall: write
	mov $1, %rdi        # file descriptor: stdout
	#lea t1(%rip), %rsi # pointer to message
	#mov $57, %rdx       # length of message
	syscall
	ret


promptf:
	lea prompt(%rip), %rsi 
	mov $26, %rdx
	call prnt
	jmp LIn
ipromptf:
	lea iprompt(%rip), %rsi
	mov $44, %rdx
	call prnt

LIn:		# --- read input ---
	mov $0, %rax         # sys_read
	mov $0, %rdi         # stdin
	lea buffer(%rip), %rsi
	mov $2, %rdx       # max bytes to read
	syscall

	# --- write input back ---
	# rdx = number of bytes read is returned in rax from sys_read
	#	mov %rax, %rdx moving number to print as number recieved
	#mov $1, %rax         # sys_write
	#mov $1, %rdi         # stdout
	#lea buffer(%rip), %rsi
	#syscall
	#jmp Boardpr

	movzbl buffer(%rip), %r10d # move buffer char to r10
	subl $48, %r10d # subtract to become 0-8
	shl $1, %r10d
	movl %r10d, %ecx
	movl $0b11 , %r12d # bit mask r12  
	#aparently, shift can only be variable when it is the lowest 8 bits of rcx, %cl
	shl %cl, %r12d # shift 2 * 0 - 8, r12 now holds the bit mask to see if this is empty

	# if statement to see if this is a valid row
	movb $0, buffer(%rip)

	testl %r12d,%r8d # Do bitwise and on board state and mask
	jnz ipromptf
	#if condition for turn based on turn variable 
	testl $1, %r9d  # will be nonzero if turn == 1
	jnz player2_skip # making it if it is one (player 2)
		movl $0b01, %r12d ## p1 is X 
		jmp post_player_if
	player2_skip:
		movl $0b10, %r12d ## P2 is #
	post_player_if:
	shl %cl, %r12d
	# Take r12d -> Bitmask to switch
	or %r12d, %r8d

	## implement logic to change 

#Clear out the upper bits so they dont interfere
and $0x3FFFF,  %r8

mov $2, %r13 # Print for loop holder
jmp printboardln
printboardln:

	call printe
	# use the value of r%13 to scrape the value of 	dd
	#can use rdi to pass to function due to it getting overwritten.
	#pass the number to rdi that will be in %r13, then the char value will be written back into rax and printed. 
	movq $2, %rdi
	call determineplace

	call printgap

	movq $1, %rdi
	call determineplace


	call printgap
	
	movq $0, %rdi
	call determineplace
	
	call printe
	
	subq $1 , %r13
	jl startcheck
	call printdiv

	jmp printboardln
	
determineplace:
	#take rdi as the first input to the function (number position)
	#Create bitmask to check if that position is zero. if it is, return that number
	#in r13 is the count (0-2), %r12 is the bitmask register, rdi gonna be 0, 1, 2
	# get number into rdi
	movq %r13, %r14
	imulq $3, %r14
	addq %rdi, %r14 # holds 0-8
	
	

	movl %r14d, %ecx #0-8
	shl $1, %ecx

	movl $0b11 , %r12d # bit mask r12  
	#aparently, shift can only be variable when it is the lowest 8 bits of rcx, %cl
	shl %cl, %r12d # shift 2 * 0 - 9, r12 now holds the bit mask to see if this is empty
	testl %r12d, %r8d

	jz open_spot
	## Logic for x or o
	movl $0b01, %r12d ## p1 is X 
	shl %cl, %r12d
	# Take r12d -> Bitmask to switch
	testl %r12d, %r8d
	jnz exbox
	lea p2(%rip), %rsi
	mov $1, %rdx
	call prnt
	ret

		
	exbox:
		lea p1(%rip), %rsi
		mov $1, %rdx
		call prnt
		ret
	
		


	open_spot:
		addq $48, %r14
		movb %r14b, buffer(%rip)
		lea buffer(%rip), %rsi
		mov $1, %rdx
		call prnt
		ret

	


## Win logic 
# bitmask buffer in r12 is gonna hold the result, of the indiviudal
# overall result gonna be held in 
# rax gonna hold the result
startcheck:
movl $0, %eax

# do bitwise and then or 
#movl %r8d, %r12d
#andl $0b101010, %r12d # 101010 bitmasks only for specified bits, if they are all 1's
#xor $0b101010, %r12d  #should be eaqual making r12d zero
#jz  printp2win # 
mov $0b010101, %rdi
mov %r9, %rdx

mov $0, %rsi
call checkfn
mov $6, %rsi
call checkfn
mov $12, %rsi
call checkfn

mov $0b01000001000001, %rdi
mov $0, %rsi
call checkfn
mov $2, %rsi
call checkfn
mov $4, %rsi
call checkfn

mov $0b000001000100010000, %rdi
mov $0, %rsi
call checkfn

mov $0b010000000100000001, %rdi
mov $0, %rsi
call checkfn

# ... 
#movl %r8d, %r12d
#andl $0b101010000000000000, %r12d # 101010 bitmasks only for specified bits, if they are all 1's
#xor $0b101010000000000000, %r12d  #should be eaqual making r12d zero
#jz printwin # 
# ...

# FFFF - 2 bytes - 16 bits
switchturn:
	xor $1, %r9

jmp promptf


printwins:
	cmp $0 , %r9
	jnz printp2win
	jmp printp1win
printp1win:
	lea p1win(%rip), %rsi
	mov $7, %rdx
	call prnt
	jmp end
printp2win:
	lea p2win(%rip), %rsi
	mov $7, %rdx
	call prnt
	jmp end



end:

#end! 
mov $60, %rax       # syscall: exit
xor %rdi, %rdi      # status 0 & clears registers
syscall

checkfn:
	#rdi holds bitmask
	#rsi holds shift 
	#rdx holds additional shift
	#r12d will hold board
	movl %r8d, %r12d
	movl %edi, %r13d #moves bitmask to r13 so it can be preserved
	movl %esi, %ecx # use rsi normal shift shift 
	shl %cl, %r13d # shift by given amount
	movl %edx, %ecx
	shl %cl, %r13d # create real mask and store in edi
	andl %r13d, %r12d # 101010 bitmasks only for specified bits, if they are all 1's 
	# apply edi mask to r12d to individual bits
	xor  %r13d, %r12d # should be equal making r12d zero
	# xor to test if all bits are set
	jz printwins
	ret

