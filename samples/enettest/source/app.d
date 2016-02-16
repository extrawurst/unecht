module app;

import std.stdio;

import unecht;
import derelict.enet.enet;
import derelict.imgui.imgui;

alias OnDataCallback = void delegate(ubyte*,size_t);

///
final class TestLogic : UEComponent
{
    mixin(UERegisterObject!());

	@Serialize
    bool isServer=false;

    private ENetHost* server=null;
    private ENetHost* client=null;
    private ENetPeer* clientPeer=null;
    private string chat;

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        DerelictENet.load();

        enet_initialize();

        auto enetVersion = enet_linked_version();

        writefln("enet: %s.%s.%s",ENET_VERSION_GET_MAJOR(enetVersion),ENET_VERSION_GET_MINOR(enetVersion),ENET_VERSION_GET_PATCH(enetVersion));
    }

    override void onDestroy() {
        super.onDestroy;

        if(server)
        {
            enet_host_destroy(server);
            server = null;
        }

        if(client)
        {
            enet_host_destroy(client);
            enet_peer_reset (clientPeer);

            client = null;
        }

        enet_deinitialize();
    }

    override void onUpdate() {
        super.onUpdate;

        if(isServer && !server)
        {
            ENetAddress address;
            
            /* Bind the server to the default localhost.     */
            /* A specific host address can be specified by   */
            /* enet_address_set_host (& address, "x.x.x.x"); */
            address.host = ENET_HOST_ANY;
            /* Bind the server to port 1234. */
            address.port = 1234;
            
            server = enet_host_create (& address /* the address to bind the server host to */, 
                32      /* allow up to 32 clients and/or outgoing connections */,
                2      /* allow up to 2 channels to be used, 0 and 1 */,
                0      /* assume any amount of incoming bandwidth */,
                0      /* assume any amount of outgoing bandwidth */);
            
            assert(server);

            writefln("server started: %s",server.address);
        }
        else if(isServer && server)
        {
            updatePeer(server, &onDataServer);

            renderEnetHostGUI(server, "server");
        }

        if(!client)
        {
            client = enet_host_create (null /* create a client host */,
                1 /* only allow 1 outgoing connection */,
                2 /* allow up 2 channels to be used, 0 and 1 */,
                57600 / 8 /* 56K modem with 56 Kbps downstream bandwidth */,
                14400 / 8 /* 56K modem with 14 Kbps upstream bandwidth */);

            ENetAddress address;

            /* Connect to some.server.net:1234. */
            enet_address_set_host (&address, "127.0.0.1");
            address.port = 1234;
            /* Initiate the connection, allocating the two channels 0 and 1. */
            clientPeer = enet_host_connect (client, &address, 2, 0);    

            writefln("client started: %s",clientPeer.address);
        }
        else
        {
            updatePeer(client, &onDataClient);

            renderEnetHostGUI(client,"client");

            igBegin("chat");
            scope(exit) igEnd();

            static string currentInput;
            if(UEGui.InputText!128("send",currentInput))
            {
                sendChat(currentInput);
                currentInput.length = 0;
            }

            UEGui.Text(chat);
        }
    }

    private void onDataServer(ubyte* data, size_t length)
    {
        /* Create a reliable packet */
        ENetPacket* packet = enet_packet_create (data, 
            length, 
            ENET_PACKET_FLAG_RELIABLE);
        
        /* Send the packet to the peer over channel id 0. */
        /* One could also broadcast the packet by         */
        /* enet_host_broadcast (host, 0, packet);         */
        enet_host_broadcast (server, 0, packet);
        
        /* One could just use enet_host_service() instead. */
        enet_host_flush (server);
    }

    private void onDataClient(ubyte* data, size_t length)
    {
        chat = to!string(cast(char[])data[0..length]) ~ "\n" ~ chat;
    }

    private void sendChat(string text)
    {
        /* Create a reliable packet */
        ENetPacket* packet = enet_packet_create (text.ptr, 
            text.length, 
            ENET_PACKET_FLAG_RELIABLE);
            
        /* Send the packet to the peer over channel id 0. */
        /* One could also broadcast the packet by         */
        /* enet_host_broadcast (host, 0, packet);         */
        enet_peer_send (clientPeer, 0, packet);

        /* One could just use enet_host_service() instead. */
        enet_host_flush (client);
    }

    private void renderEnetHostGUI(ENetHost* host, const(char)* name)
    {
        igBegin(name);
        scope(exit) igEnd();
        
        igText("incomingBandwidth: %d",        host.incomingBandwidth);
        igText("outgoingBandwidth: %d",        host.outgoingBandwidth);
        igText("bandwidthThrottleEpoch: %d",   host.bandwidthThrottleEpoch);
        igText("mtu: %d",                      host.mtu);
        igText("totalSentData: %d",            host.totalSentData);
        igText("totalSentPackets: %d",         host.totalSentPackets);
        igText("totalReceivedData: %d",        host.totalReceivedData);
        igText("totalReceivedPackets: %d",     host.totalReceivedPackets);
        igText("connectedPeers: %d",           host.connectedPeers);
        igText("peerCount: %d",                host.peerCount);
        igText("bandwidthLimitedPeers: %d",    host.bandwidthLimitedPeers);

        foreach(i, p; host.peers[0..host.peerCount])
        {
            if(p.state != ENET_PEER_STATE_DISCONNECTED)
            {
                if(UEGui.TreeNode(format("peer %s",i)))
                {
                    UEGui.Text(format("state: %s",p.state));
                    igText("incomingBandwidth: %d", p.incomingBandwidth);
                    igText("outgoingBandwidth: %d", p.outgoingBandwidth);
                    igText("incomingDataTotal: %d", p.incomingDataTotal);
                    igText("outgoingDataTotal: %d", p.outgoingDataTotal);
                    igText("packetsSent: %d", p.packetsSent);
                    igText("packetsLost: %d", p.packetsLost);
                    igText("pingInterval: %d", p.pingInterval);
                    igText("lastRoundTripTime: %d", p.lastRoundTripTime);
                    igText("lowestRoundTripTime: %d", p.lowestRoundTripTime);
                    igText("lastRoundTripTimeVariance: %d", p.lastRoundTripTimeVariance);
                    igText("highestRoundTripTimeVariance: %d", p.highestRoundTripTimeVariance);
                    igText("roundTripTime: %d", p.roundTripTime);
                    igText("mtu: %d", p.mtu);

                    igTreePop();
                }
            }
        }
    }

    private void updatePeer(ENetHost* peer, scope OnDataCallback onData)
    {
        ENetEvent event;
        while (enet_host_service (peer, &event, 0) > 0)
        {
            final switch (event.type)
            {
                case ENET_EVENT_TYPE_CONNECT:
                    writefln("peer connected: %s",event.peer.address);
                    break;

                case ENET_EVENT_TYPE_RECEIVE:
                    onData(event.packet.data, event.packet.dataLength);

                    /* Clean up the packet now that we're done using it. */
                    enet_packet_destroy (event.packet);
                    break;

                case ENET_EVENT_TYPE_DISCONNECT:
                    writefln("peer disconnected: %s",event.peer.address);
                    /* Reset the peer's client information. */
                    event.peer.data = null;
                    break;

                case ENET_EVENT_TYPE_NONE:
                    writefln("peer event: %s",event.type);
                    enet_packet_destroy (event.packet);
                    break;
            }
        }
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();
        }
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - enet test sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!TestLogic;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}