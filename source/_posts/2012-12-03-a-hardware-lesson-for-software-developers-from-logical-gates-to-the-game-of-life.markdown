---
layout: post
title: "A hardware lesson for software developers: from logical gates to the game of life"
date: 2012-12-03 23:04
comments: true
categories: [VHDL, hardware, crazy]
---

A week ago I've decided to learn VHDL and as an exercise, implement [The game of life](http://en.wikipedia.org/wiki/Conway's_Game_of_Life).  
VHDL is a hardware definition language. Meaning, a language that is compiled to hardware. 

**Why write this post?**  
I thought it'd be interesting to see what it takes to develop a chip. Coming from software, I was specifically curious about the programming model and mindset.  
I think every programmer should be familiar with the layers he relies on; Not every Python programmer knows C, And not every C programmer knows assembler. But when the shit hits the fan, this knowledge comes in handy.

**Required knowledge**  
I'm going to assume you know nothing about hardware and a little about software.  
VHDL is based on Ada so you might even find it familiar.

Booleans all the way down
-------------------------

Most hardware these days deeply relies on boolean logic, here's why:

* Boolean algebra has been around for ages - simple boolean operations like 'and', 'or' and 'not' can compose incredibly sophisticated algorithms (calculators, modems, CPUs!).
* Passing boolean data is easy in hardware. you pass electricity through a wire to indicate a **true** state and stop passing electricity to indicate a **false** state.

**Light bulb moment: ever wondered why integers in software are powers of two?**  
A CPU has a fixed amount of wires (32/64) dedicated to represent data (a.k.a word size).  
each wire represents a bit that can be true or false (1 or 0).  
The binary numeral system is used to represent a number in a bunch of 1s and 0s.

Dive into VHDL - the life of a gate
-----------------------------------

Let's start off with an implementation of an 'and' gate:

{% include_code And Gate lang:vhdl and.vhdl %}

What's happening in the code line by line:

1-2: Include the module that exports the std_logic type which is a simple bit (can be 0 or 1).  
4: Define a new entity. An entity is analogous to an object in OOP.  
5: the entity interacts with other entities using ports. input ports are used to receive information and output ports are used to send information.  
6: define two inputs of type std_logic.  
7: define one output of type std_logic.  
11: the architecture is the implementation of the object's behavior. it's name (arch) is redundant as only one architecture is allowed.  
13: the actual implementation of an 'and' gate. **every time** one of the inputs changes the output is recalcualted.

By using a synthesis tool we can convert this code to a hardware schematic:

{% img /images/vhdl_post/and.png Schematic of the 'and' component %}

Think parallel - a simple adder
-------------------------------

We'll implement an adder that takes two bit-sized inputs (x and y) and adds them to a two-bit output (sum_0 and sum_1).
The following table demonstrates the adder's functionality:

<table>
	<tr>
		<th width="50">x</th>
		<th width="50">y</th>
		<th width="50">sum_1</th>
		<th width="50">sum_0</th>
		<th width="140">sum as binary</th>
		<th width="140">sum as int</th>
	</tr>
	<tr>
		<td>0</td>
		<td>0</td>
		<td>0</td>
		<td>0</td>
		<td>0</td>
		<td>0</td>
	</tr>
	<tr>
		<td>0</td>
		<td>1</td>
		<td>0</td>
		<td>1</td>
		<td>1</td>
		<td>1</td>
	</tr>
	<tr>
		<td>1</td>
		<td>0</td>
		<td>0</td>
		<td>1</td>
		<td>1</td>
		<td>1</td>
	</tr>
	<tr>
		<td>1</td>
		<td>1</td>
		<td>1</td>
		<td>0</td>
		<td>10</td>
		<td>2</td>
	</tr>
</table>

<br/>

Now let's look at the code:

{% include_code Adder lang:vhdl adder.vhdl %}

Look at lines 13-14. When does this code execute? Is line 13 executed before line 14?  
The answer is: these lines execute all the time, **in parallel!**

> This is a major difference from software written for CPUs:  
> **VHDL is concurrent by default**.

VHDL has the notion of *concurrent* statements and *sequential* statements. Sequential statments can be used to implement state machines and other sequential procedures. We'll see an example later on.

Testing using sequential code
-----------------------------

VHDL programmers (often called designers) write tests frequently. They call them 'test benches' or 'simulations'.

The test will be a separate entity. In order to verify the adder's functionality we'll have to drive different inputs and check the sum.

{% include_code And Gate lang:vhdl test_adder.vhdl %}

9-14: repetition of the adder's interface (VHDL isn't very DRY)  
16: signals are wires that the test can manipulate. their type is std_logic (a bit)  
19-22: a port map connects the signals to the adder. The signals are named exactly as the adder's ports (the syntax: SIGNAL_NAME => PORT_NAME)  
24: the process definition. A process contains a list of **sequential** statements. Multiple processes can run concurrently.  
26-27: signal assignments.  
28: signals have an interesting behavior where the assignment takes effect only when calling 'wait'. This is a feature and not a bug as it allows doing atomic changes over multiple signals.  
29: assert the sum changed

The following lines test the remaining test cases. 

Here's the simulation in wave form:

{% img /images/vhdl_post/adder_test.png 800 300 Waveform of adder_test.vhdl %}

The game of life
----------------

Let's start with a typical software-based solution:

1. The board is a matrix of booleans representing cells.
2. For each cycle: the next board is generated by iterating over the matrix, for each cell: count it's neighbors and determine if it should be alive or dead.

When trying to apply this design in VHDL I quickly ran into brick walls. A sequential iteration over an entire matrix is not the VHDL 'way'. My guess is that a sequential design would generate much more logical gates and perhaps even be slower.

> Software is often bound by memory and CPU  
> Chip design is often bound by gates and timing issues.

VHDL encourages you to build small components and inter-connect them where needed. each component has it's own hardware resources and works in parallel to others.

The design I came up with is the following:

1. *Cell* - is an entity. connected to it's neighbors via ports. has an independent process for counting the neighbors and setting the next state. 
2. *Board* - is a matrix of cells. all it does is inter-connects them.

Here's the cell's code:

{% include_code Adder lang:vhdl cell.vhdl %}

3: generics are variables that can be set upon entity instantiation. similar to constructor arguments.  
19: notice the process gets an argument? a process can state a list of signals (also called a sensitivity list) that should trigger it's invocation. that way, the cell will calculate it's next state every time the clock changes.  
20: variables are exactly what you think they. notice we limit the integer's range to 8? that's because we'll have a maximum of 8 neighbors.


{% img /images/vhdl_post/board.png Schematic of a two cell board %}


Conclusions
-----------

Why create new circuits and not use cpus? power consumption, performance, size, money, response time

> software - write serial code, parallelize when need to scale.  
> hardware - write concurrent code, write serial code where needed.

One of the most challenging concepts in software is concurreny. It's interesting how fundamental this topic is to hardware. 

Scalabillity - How the design scales for a large amount of cells?
The software-based solution has several limits:
memory-wise: limited by the amount of memory
speed-wise: iteration is done serially and will be directly proportional to the amount of cells. (even if you utilize multiple cores)

The hardware-based solution is said to be scalable. adding more cells results in adding more logical gates. there is no performance overhead and no arbitrary limit on the number of cells in the matrix.

Tools
-----

The eco-system around 

ghdl (for mac!)
xilinix on windows or schematic generation
gtkwave using ghdl 
