module unecht.core.logger;

public import std.experimental.logger:Logger;

Logger log;

shared static this()
{
    import std.stdio:stdout;
    import std.experimental.logger:MultiLogger,FileLogger,sharedLog;

    auto logger = new MultiLogger();
    logger.insertLogger("stdout",new FileLogger(stdout));
    logger.insertLogger("unechtlog",new FileLogger("unecht.log"));
    log = logger;

    sharedLog = log;
}