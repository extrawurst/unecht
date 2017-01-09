/++
 + Authors: Stephan Dilly, lastname dot firstname at gmail dot com
 + Copyright: MIT
 +/
module unecht.core.fibers;

public import core.thread:Fiber;
import core.thread:Thread;
import std.datetime:Duration;

import derelict.util.system;

/// function type that can be used as a fiber
alias UEFiberFunc = void function();
/// delegate type that can be used as a fiber
alias UEFiberDelegate = void delegate();

/++
 + acts like a std.thread.Fiber - adds child Fiber member to enable yield on child fibers (=wait for child fiber to finish)
 +
 + See_Also:
 +	`UEFibers`
 +/
final class UEFiber : Fiber
{
	/// pointer to child Fiber
	private Fiber child;

	//TODO: make nothrow once we loose the dmd<2067 compat
	/// c'tor
	public this(T)( T fn )
		if(is(T == UEFiberFunc) || is(T == UEFiberDelegate))
	{
		super(fn);

		initParent();
	}

	/// resets the Fiber to be reused with another method
	public void reset(T)( T fn )
		if(is(T == UEFiberFunc) || is(T == UEFiberDelegate))
	{
		super.reset(fn);

		initParent();
	}

	/// usage of `reset`
	unittest
	{
		bool res;
		auto fiber = new UEFiber(cast(UEFiberDelegate){res = false;});
		fiber.reset(cast(UEFiberDelegate){res = true;});
		fiber.call();
		assert(res);
	}

	/// initializes parents child property to point to this
	private void initParent()
	{
		UEFiber parent = cast(UEFiber)Fiber.getThis();
		if(parent)
		{
			assert(parent.child is null);
			parent.child = this;
		}
	}

	/// will call the Fiber in a nothrow way, so it will return any thrown exception inside without automatic rethrow
	public void safeCall()
	{
		static if(__VERSION__ >= 2067)
			auto e = call(Fiber.Rethrow.no);
		else
			auto e = call(false);

		if(e)
		{
			static if(__VERSION__ < 2067)
			{
				import std.stdio:writefln;
				writefln("error: %s",e);
			}
			else
			{
				import std.experimental.logger:errorf;
				errorf("error: %s",e.toString());
			}
		}
	}
}

///
unittest
{
	int i=0;
	auto fiber = new UEFiber(cast(UEFiberDelegate){
			i++;
			Fiber.yield;
			i++;
		});

	fiber.call(); // executes until yield
	assert(i == 1);

	fiber.call(); // finishes
	assert(i == 2);
}

/++
 + returns a function object that can be used to wait in a `UEFiber` for a certain amount of time
 +
 + Params:
 +	d =	a string that will be mixed in and has to evaluate to a `DateTime`
 +
 + Returns: A function object
 +
 + See_Also:
 +	`UEFiber`, `UEFiberFunc`
 +
 + Examples:
 + ---
 + UEFibers.yield(waitFiber!"2.seconds");
 + ---
 +/
UEFiberFunc waitFiber(string d)()
{
	import std.datetime;

	return {
		auto targetTime = Clock.currTime + mixin(d);
		while(Clock.currTime < targetTime)
			Fiber.yield;
	};
}

/++
 + UEFibers acts as a container for fibers.
 + It manages reusing `UEFiber` objects after they are finished.
 + `startFiber` first tries to find a finished `UEFiber` and only otherwise allocates
 +
 + See_Also:
 +	`UEFiber`
 +/
struct UEFibers
{
	private static UEFiber[] fibers;

	/// start a function as a fiber
	public static void startFiber(UEFiberFunc func)
	{
		import std.functional:toDelegate;

		startFiber(func.toDelegate());
	}

	/// ditto
	public static void startFiber(UEFiberDelegate func)
	{
		UEFiber newFiber = findFreeFiber();

		if(newFiber)
		{
			newFiber.reset(func);
		}
		else
		{
			newFiber = new UEFiber(func);
			fibers ~= newFiber;
		}

		newFiber.safeCall();
	}

	//TODO: when runFibers moves TERM'd fibers to end then iterate over array in reverse
	private static UEFiber findFreeFiber()
	{
		foreach(f; fibers)
		{
			if(f.state == Fiber.State.TERM)
				return f;
		}

		return null;
	}

	/// yield the current fiber until func is finished running
	public static yield(UEFiberDelegate func)
	{
		assert(Fiber.getThis());

		startFiber(func);

		Fiber.yield();
	}

	/// ditto
	public static yield(UEFiberFunc func)
	{
		import std.functional:toDelegate;
		yield(func.toDelegate());
	}

	//TODO: move Fibers in TERM state to the end of array
	/++
	 + Calls all running fibers that do not wait for a child to finish
	 +
	 + Note: Do not count on the order of execution of fibers, they could be reordered
	 +/
	public static void runFibers()
	{
		foreach(f; fibers)
		{
			if(f.state != Fiber.State.TERM)
			{
				if(!f.child)
				{
					f.safeCall();
				}
				else
				{
					if(f.child.state == Fiber.State.TERM)
					{
						f.child = null;
						f.safeCall();
					}
				}
			}
		}
	}
}

/// basic yield
unittest
{
	int i=0;
	// reset
	UEFibers.fibers.length=0;

	UEFibers.startFiber({
		i++;
		Fiber.yield();
		i++;
	});

	assert(i==1);
	UEFibers.runFibers();
	assert(i==2);
}

/// fiber object reuse
unittest
{
	int i=0;
	// reset
	UEFibers.fibers.length=0;

	UEFibers.startFiber({i++;});
	UEFibers.startFiber({i++;});

	assert(UEFibers.fibers.length == 1);
	assert(i == 2);
}

unittest
{
	// test yield on other fibers

	string log;

	UEFibers.fibers.length=0;

	auto f1 = {
		log ~= 'b';
		Fiber.yield();
		log ~= 'c';
	};

	UEFibers.startFiber(
		{
			log ~= 'a';
			UEFibers.yield(f1);
			log ~= 'd';
		});

	assert(UEFibers.fibers.length == 2);
	assert(log=="ab", log);

	UEFibers.runFibers();

	assert(log=="abc");

	UEFibers.runFibers();

	assert(log=="abcd");

	UEFibers.startFiber(
		{
			log ~= 'e';
		});

	assert(log=="abcde");

	assert(UEFibers.fibers.length == 2);
}

unittest
{
	// test reusing fibers

	int i;

	UEFibers.fibers.length=0;

	auto f1 = {
		Fiber.yield();
		i++;
	};

	foreach(j; 0..5)
		UEFibers.startFiber(f1);

	assert(UEFibers.fibers.length == 5);
	assert(i == 0);

	UEFibers.runFibers();

	assert(i == 5);

	foreach(j; 0..5)
		UEFibers.startFiber(f1);

	assert(UEFibers.fibers.length == 5);
	assert(i == 5);

	UEFibers.runFibers();

	assert(i == 10);

	assert(UEFibers.fibers.length == 5);
}

unittest
{
	// test wait fiber

	import std.datetime;

	UEFibers.fibers.length = 0;
	bool run=false;

	auto now = Clock.currTime;
	UEFibers.startFiber(
		{
			UEFibers.yield(waitFiber!"1.msecs");

			run = true;
		});

	int cycles=0;
	while(!run)
	{
		UEFibers.runFibers();
		cycles++;
	}

	assert(Clock.currTime - now >= 1.msecs);
	assert(cycles > 10, "this should at least take 10 cylces");
}

unittest
{
	// test bug about resetting existing fibers

	import std.datetime;

	UEFibers.fibers.length = 0;
	auto run=0;

	auto now = Clock.currTime;
	UEFibers.startFiber(
		{
			foreach(i; 0..5)
			{
				UEFibers.yield(waitFiber!"1.msecs");

				run++;
			}
		});

	while(run<5)
	{
		UEFibers.runFibers();
	}

	assert(UEFibers.fibers.length == 2);
	assert(Clock.currTime - now >= 5.msecs);
}
