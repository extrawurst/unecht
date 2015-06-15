module unecht.core.logger;

import unecht.core.staticRingBuffer;

static if(__VERSION__ >= 2067)
{
    public import std.experimental.logger:Logger;

    Logger log;
    HistoryLogger logHistory;

    ///
    final class HistoryLogger : Logger
    {
        import std.experimental.logger;

        StaticRingBuffer!(100, LogEntry) history;

        this() @safe
        {
            super(LogLevel.all);
        }
        
        override void writeLogMsg(ref LogEntry payload)
        {
            history ~= payload;
        }
    }

    shared static this()
    {
        import std.stdio:stdout;
        import std.experimental.logger:MultiLogger,FileLogger,sharedLog;

        logHistory = new HistoryLogger();

        auto logger = new MultiLogger();
        logger.insertLogger("stdout", new FileLogger(stdout));
        logger.insertLogger("unechtlog", new FileLogger("unecht.log"));
        logger.insertLogger("history", logHistory);
        log = logger;

        sharedLog = log;
    }
}
else
{
    struct Logger
    {
        void info(string str)
        {
            import std.stdio;
            writeln(str);
        }

        void infof(ARGS...)(string str, ARGS args)
        {
            import std.stdio;
            writefln(str,args);
        }

        alias error = info;
        alias errorf = infof;
        alias warning = info;
        alias warningf = infof;
    }

    Logger log;
}
