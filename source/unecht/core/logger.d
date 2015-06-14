module unecht.core.logger;

public import std.experimental.logger:Logger;

Logger log;

shared static this()
{
    import std.stdio:stdout;
    import std.experimental.logger:MultiLogger,FileLogger;

    auto logger = new MultiLogger();
    logger.insertLogger("stdout",new FileLogger(stdout));
    logger.insertLogger("unechtlog",new FileLogger("unecht.log"));
    log = logger;

    import std.experimental.logger.core:stdlog;
    stdlog = log;
    
    //import std.experimental.logger.core:sharedLog;
    //sharedLog = log;
}