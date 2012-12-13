---
layout: post
title: "A hardware lesson for software developers: from logical gates to the game of life"
date: 2012-12-03 23:04
comments: true
categories: [VHDL, hardware, crazy]
---

A week ago I've decided to learn VHDL and as an exercise, implement [The game of life](http://en.wikipedia.org/wiki/Conway's_Game_of_Life).  
VHDL is a hardware description language. Basically, it's a programming language used by chip designers.  

**Why learn VHDL?**  
I thought it'd be interesting to see what it takes to program a chip. Coming from software, I was specifically curious about the programming model and mindset. Think about it, all software eventually translates to cpu instructions. What's underneath that?..  

It's my belief that every programmer should be familiar with the layers he relies on.  
Not every Python programmer knows C, and not every C programmer knows assembler. But when the shit hits the fan, this knowledge comes in handy.

**Required knowledge**  
I'm going to assume you know nothing about hardware and a little about software.  
VHDL is based on Ada so you might even find it familiar.

Booleans all the way down
-------------------------

Most hardware these days is based on boolean logic, here's why:

* Boolean algebra has been around for ages - simple boolean operations like 'and', 'or' and 'not' can compose incredibly sophisticated algorithms (calculators, modems, CPUs!).
* Passing boolean data is easy in hardware, you pass electricity through a wire to indicate a **true** state and stop passing electricity to indicate a **false** state.

**Light bulb moment: ever wondered why integers in software are powers of two?**  
A CPU has a fixed amount of wires (32/64) dedicated to represent data (a.k.a word size).  
Each wire represents a bit that can be true or false (1 or 0).  
The binary numeral system is used to represent a number in a bunch of 1s and 0s.

Dive into VHDL - the life of a gate
-----------------------------------

Let's start off with an implementation of an 'and' gate:

{% include_code And Gate lang:vhdl and.vhdl %}

What's happening in the code line by line:

1-2: Include the module that exports the std_logic type which represents a bit (can be 0 or 1).  
4: Define a new entity. **An entity is analogous to an object in object oriented programming**.  
5: The entity interacts with other entities using ports. Input ports are used to receive information and output ports are used to send information.  
6: Define two inputs of type std_logic.  
7: Define one output of type std_logic.  
11: The architecture is the implementation of the object's behavior. It's name (arch) is redundant as only one architecture is allowed.  
13: The implementation of an 'and' gate. **Every time** an input changes the output is recalcualted.

By using a synthesis tool we can convert this code to a hardware schematic:

{% img /images/vhdl_post/and.png Schematic of the 'and' component %}

Think parallel - a simple adder
-------------------------------

We'll implement an adder that takes two bit-sized inputs (x and y) and adds them to a two-bit output (sum_0 and sum_1. sum_1 is the carry).
The following table demonstrates the adder's functionality:

<table>
	<tr>
		<th width="60">x</th>
		<th width="60">y</th>
		<th width="60">sum_1</th>
		<th width="60">sum_0</th>
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

> A major difference between software written for CPUs and VHDL is:  
> **VHDL is concurrent by default**.

VHDL has the notion of *concurrent* statements vs. *sequential* statements.  
Sequential statments can be used to implement state machines and other sequential procedures. 

Testing using sequential code
-----------------------------

The hardware manufacturing phase of a chip is long and expensive, therefore, VHDL programmers (often called designers) write tests (often called 'testbenches' or 'simulations').  

The following test code will verify the adder's functionality by driving different inputs and verifying the output (explanation ahead):

{% include_code Test Adder lang:vhdl test_adder.vhdl %}

4: Define an entity for the test. This entity has no inputs and outputs.  
9-14: Repetition of the adder's interface (VHDL isn't very DRY)  
16: Signals are wires that the test can manipulate. their type is std_logic (a bit)  
19-22: A port map connects the signals to the adder's ports. I named the signals exactly as the adder's ports.  
24: The process definition. A process contains a list of **sequential** statements. Multiple processes run concurrently.  
26-27: Signal assignments.  
28: Signals have an interesting behavior where the assignment takes effect only when calling 'wait'. This is a feature and not a bug as it allows doing atomic changes over multiple signals.  
29: Assert the sum changed.  
30 Until the end: Test the remaining cases.

Here's the simulation in wave form:

{% img /images/vhdl_post/adder_test.png 800 300 Waveform of adder_test.vhdl %}

**Note**: Some VHDL statements are not *synthesizable*, meaning they cannot be converted to hardware and can only be used for simulations.  
An example is the *wait* statement. A 1 nano second sleep cannot be expressed solely by logical gates.
The solution for time-aware components is connecting to a high speed clock (Implemented using a [Crystal oscillator](http://en.wikipedia.org/wiki/Crystal_oscillator)), we'll see an example ahead.

The game of life
----------------

Let's start with a typical software-based solution:

1. The board is a matrix of booleans representing cells.
2. For each cycle: the next board is generated by iterating over the matrix, for each cell: count it's neighbors and determine if it should live or die.

When trying to apply this design in VHDL I quickly ran into brick walls. A sequential iteration over an entire matrix is not the VHDL 'way'. My guess is that a sequential design would generate much more logical gates and perhaps even be slower.

> Software is often bound by memory and CPU.  
> Chip design is often bound by the amount of gates and timing issues which surface when signals travel through large amounts of gates.

VHDL encourages you to build small components and inter-connect them where needed.  
each component has it's own hardware resources and works in parallel to others.

The design I came up with is the following:

1. *Cell* - Is an entity. Connected to it's neighbors via ports. The cell waits for a clock signal, counts his live neighbors and sets it's alive state.
2. *Board* - Is another entity. Contains a matrix of cells. All it does is inter-connects them.

Here's the cell's code:

{% include_code Cell lang:vhdl cell.vhdl %}

3: Generics are variables that can be set upon entity instantiation. Somewhat similar to constructor arguments in object oriented languages.  
19: Notice the process gets an argument? A process can state a list of signals (also called a sensitivity list) that should trigger it's invocation. That way, the cell will calculate it's next state every time the clock changes.  
20: Variables are exactly what you think they. Notice we limit the integer's range to 8? that's because we'll have a maximum of 8 neighbors. VHDL dedicate only 4 wires for that variable.

{% img /images/vhdl_post/board.png Schematic of a two cell board %}

Conclusions
-----------

**Scalabillity - How the design scales for a large amount of cells?**

The software-based solution has several limits:

* Memory-wise: limited by the amount of memory.
* Speed-wise: iteration is done serially and will be directly proportional to the amount of cells, even if multiple cores are utilized.

The hardware-based solution is said to be scalable:

* Adding more cells results in adding more logical gates.
* There is no performance overhead and no arbitrary limit on the number of cells in the matrix.

**Change of mindset**  
One of the most challenging concepts in software is concurreny, it's interesting how fundamental this topic is to hardware.
> Software - write serial code, parallelize when need to scale.  
> Hardware - write concurrent code, write serial code where needed.

**Why bother manufacturing new chips and not re-use CPUs?**  
Here are a few reasons I can come up with:

1. *Power consumption* of CPUs can render them unusable for many applications (Battery size/life).  
2. *Performance* of ASICs (Application specific integrated circuits - chips created for a specific task) can work faster compared to CPUs (That's why GPUs became popular).
3. *Price per unit* can drop drastically for large amounts of ASICs (compare a chip that does bluetooth to an Intel CPU).

Tools
-----

* ghdl (for mac!) is a VHDL compiler
* Xilinix on windows for schematic generation
* gtkwave for visualing simulations
