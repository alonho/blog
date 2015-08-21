---
layout: post
title: "Argument binding in python"
date: 2013-10-20 19:39
comments: true
categories: 
---

After a recent debate about argument binding I decided to list some pros and cons of the different methods to bind arguments in python. Let's start with a review of available methods:

{% codeblock argument binding lang:python %}

def add(x, y):
    return x + y

from functools import partial
add5_partial = partial(add, 5)
add5_partial(10) # 15

add5_lambda = lambda x: add(x, 5)
add5_lambda(10) # 15

{% endcodeblock %}

## My beef with partial

`partial` is not a function and misbehaves where functions are expected. `partial` can be easily implemented in pure python but I can only guess it was implemented in C for performance considerations. Lets review some examples:

### 1. Partial doesn't work on methods:

{% codeblock partial on methods lang:python %}

from functools import partial

class Cell(object):
    def set_state(self, state):
        self._state = state
    set_alive = partial(set_state, state=True)
    set_dead = partial(set_state, state=False)

>>> Cell().set_alive()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: set_state() missing 1 required positional argument: *self*

{% endcodeblock %}

####Why is that?


You know how `self` always gets assigned the instance when calling an instance method?
Well, it's implemented using a mechanism called descriptors. In order to support that functionality the function type implements a `__get__` method. 

Here's how a method call works:

{% codeblock methods explained lang:python %}

class Person(object):
    def __init__(self, name):
        self._name = name
    def speak(self):
        print 'My name is', self._name

>>> p = Person('Neo')
>>> p.speak() # a method call
My name is Neo

>>> # so what's the difference between a method and a function?
>>> method = p.speak # the method encaspulates the function and the instance
>>> method
<bound method Person.speak of <__main__.Person object at 0x109d7bb90>>
>>> method.im_self # that's where self is hiding!
<__main__.Person object at 0x109d7bb90>>
>>> method.im_func # that's where the function is hiding!
<function Person.speak at 0x106163950>
>>> method() # same as: method.im_func(method.im_self)
My name is Neo

>>> # what transforms a function into a method?
>>> Person().speak # triggers __getattribute__('speak') 
>>> # __getattribute__ looks for the attribute in the instance's __dict__
>>> # __getattribute__ then looks for the attribute in the class's __dict__
>>> # after it finds it, it checks if the value (a function) implements a __get__ method
>>> # if it doesn't implement __get__, return the value
>>> # if it does, return whatever __get__ returns
>>> method = Person.speak.__get__(Person('Neo'))
>>> method
<bound method Person.speak of <__main__.Person object at 0x109d7bb90>>

{% endcodeblock %}

### 2. `partial` cannot be inspected:

{% codeblock inspect and partial lang:python %}

>>> import inspect, functools
>>> p = functools.partial(lambda x, y: x + y, 10)
>>> inspect.getargspec(p)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/lib/python3.3/inspect.py", line 823, in getargspec
    getfullargspec(func)
  File "/usr/lib/python3.3/inspect.py", line 850, in getfullargspec
    raise TypeError('{!r} is not a Python function'.format(func))
TypeError: functools.partial(<function <lambda> at 0x1073065f0>, 10) is not a Python function

>>> print p.__doc__ # doesn't preserve the wrapped function's __doc__
partial(func, *args, **keywords) - new function with partial application of the given arguments and keywords.

{% endcodeblock %}

### 3. `partial` could be safer, validating argument counts and names:

{% codeblock argument validation lang:python %}

>>> from functools import partial
>>> f = partial(lambda: None, 1, 2, 3) # why not verify signature here?!
>>> f()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: <lambda>() takes no arguments (3 given)

{% endcodeblock %}

###Alternatives to partial

You could implement your own partial, that actually returns a function:

{% codeblock an alternative partial lang:python %}

from functools import wraps

def partial(func, *a, **k):
    @wraps(func)
    def new_func(*args, **kwargs):
        return func(*(a + args), **dict(k, **kwargs))
    return new_func

{% endcodeblock %}

**Note:** don't use this code, it doesn't enforce unique keyword arguments.

You could also use a lambda function:

{% codeblock lambda as partial method lang:python %}

class Cell(object):
     def set_state(self, state):
         self._state = state
     set_alive = lambda self: self.set_state(True)
     set_dead = lambda self: self.set_state(False)

{% endcodeblock %}

My problem with lambdas
-----------------------

As my friend @EyalIL wrote: 
> Lambdas capture the variable, partial captures the value. 

> The latter is much more often useful.

Here's an example to make that sentence clearer:

{% codeblock lambda bug lang:python %}

callbacks = []
for i in xrange(5):
    callbacks.append(lambda: i)
>>> print [callback() for callback in callbacks]
[4, 4, 4, 4, 4]

{% endcodeblock %}

Why is this happening? 

Because python supports closures (which are usually a good thing):

{% codeblock closures explained lang:python %}

var = 1
f = lambda: var
print f() # 1
var = 2
print f() # 2
# but, but, how does python know?! well, a function can hold references to variables in outer scopes
print f.func_closure() # (<cell at 0x101bdfb40: int object at 0x7fd3e9c106d8>,)
# what are these cells? the cell is basically a pointer to some name in some scope. holding a reference promises changes to be reflected even when changing immutable datatypes.
print f.func_closure()[0].cell_contents # 2

{% endcodeblock %}

A solution would be to bind variables who aren't function arguments as function arguments:

{% codeblock lambdas with default args lang:python %}

callbacks = []
for i in xrange(5):
    callbacks.append(lambda x=i: x)
>>> print [callback() for callback in callbacks] 
[0, 1, 2, 3, 4]
    
{% endcodeblock %}

##Can we do better?##

I'd like to propose a mechanism similar to Javascript's `Function.bind` functionality. 

Here's how I'd like it to behave (this is a proposal, the code doesn't actually work):

{% codeblock bind examples lang:python %}

def add(x, y):
    return x + y

from functools import partial
add5_partial = partial(add, 5) # requires an import
add5_lambda = lambda x: add(x, 5) # pretty long

add5_bind = add.bind(5) # shortest
import inspect
>>> print inspect.getargspec(add)
ArgSpec(args=['x', 'y'], varargs=None, keywords=None, defaults=None)
>>> print inspect.getargspec(add5_bind) # works with inspect
ArgSpec(args=['y'], varargs=None, keywords=None, defaults=None)

{% endcodeblock %}

If you dig `bind`, please comment/vote. Given enough feedback I'll be motivated to write a PEP.



