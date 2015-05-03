module app;

import std.stdio;

import unecht;
import derelict.openal.al;

///
final class CloseLogic : UEComponent
{
    mixin(UERegisterComponent!());

    private SoundSource snd;

    override void onCreate() {
        super.onCreate;
        
        registerEvent(UEEventType.key, &OnKeyEvent);

        snd = entity.addComponent!SoundSource;
        snd.play();
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();

            if(_ev.keyEvent.key == UEKey.space)
                snd.play();
        }
    }
}

///
final class SoundSource : UEComponent
{
    mixin(UERegisterComponent!());

    static immutable string testSound = import("beep.wav");
    
    private uint al_source;
    private uint al_buffer;
    
    override void onCreate() {
        super.onCreate;

        alGenSources(1, &al_source); 

        loadWAV(testSound);
    }

    void play()
    {
        writefln("play:");

        alSourcePlay(al_source);
    }

    struct WAVHeaderData
    {
        char[4] chunkType;
        int chunkSize;
    }

    struct WAVHeaderFormat
    {
        char[3] chunkType;
        int chunkSize;
        short wFormatTag;
        ushort wChannels;
        uint  dwSamplesPerSec;
        uint  dwAvgBytesPerSec;
        ushort wBlockAlign;
        ushort wBitsPerSample;
    }

    private void loadWAV(string content)
    {
        if (content[0..4] != "RIFF")
            throw new Exception("Not a WAV file");

        if (content[8..12] != "WAVE")
            throw new Exception("Not a WAV file");

        WAVHeaderFormat hdr = *cast(WAVHeaderFormat*)&content[12];

        writefln("hdr: %s",hdr);

        WAVHeaderData dat = *cast(WAVHeaderData*)&content[12+WAVHeaderFormat.sizeof];

        writefln("dat: %s",dat);

        auto duration = cast(float)dat.chunkSize / hdr.dwAvgBytesPerSec;
        writefln("dur: %s",duration);

        ubyte* dataStart = cast(ubyte*)&content[12+WAVHeaderFormat.sizeof+WAVHeaderData.sizeof];

        auto fmt = AL_FORMAT_MONO8;
        if(hdr.wBitsPerSample == 8 && hdr.wChannels == 2)
            fmt = AL_FORMAT_STEREO8;
        else if(hdr.wBitsPerSample == 16 && hdr.wChannels == 1)
            fmt = AL_FORMAT_MONO16;
        else if(hdr.wBitsPerSample == 16 && hdr.wChannels == 2)
            fmt = AL_FORMAT_STEREO16;
    
        alGenBuffers(1, &al_buffer);

        alBufferData(al_buffer, fmt, dataStart, dat.chunkSize, hdr.dwSamplesPerSec);

        alSourcei(al_source, AL_BUFFER, al_buffer);
    }
}

///
final class SoundSystem : UEComponent
{
    mixin(UERegisterComponent!());

    private ALCdevice* al_device;
    private ALCcontext* al_context;

    override void onCreate() {
        super.onCreate;

        DerelictAL.load();

        // Initialize OpenAL audio
        al_device = alcOpenDevice(null);
        al_context = alcCreateContext(al_device, null);
        alcMakeContextCurrent(al_context);
    }

    override void onDestroy() {
        super.onDestroy;

        alcDestroyContext(al_context);
        alcCloseDevice(al_device);
        al_context = al_device = null;
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - enet test sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!SoundSystem;
        newE.addComponent!CloseLogic;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}