module unecht.core.components.internal.gui;

import std.string:toStringz;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.sceneNode;
import unecht.core.events;

import gl3n.linalg;

import derelict.imgui.imgui;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

///
final class UEGui : UEComponent 
{    
public:
    mixin(UERegisterComponent!());
    
    override void onCreate() {
        import unecht;

        registerEvent(UEEventType.text, &OnCharInput);
        registerEvent(UEEventType.key, &OnKeyInput);
        registerEvent(UEEventType.mouseScroll, &OnScrollInput);

        g_window = ue.application.mainWindow.window;

        ImGuiIO* io = ig_GetIO();

        io.KeyMap[ImGuiKey_Tab] = GLFW_KEY_TAB;                 // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
        io.KeyMap[ImGuiKey_LeftArrow] = GLFW_KEY_LEFT;
        io.KeyMap[ImGuiKey_RightArrow] = GLFW_KEY_RIGHT;
        io.KeyMap[ImGuiKey_UpArrow] = GLFW_KEY_UP;
        io.KeyMap[ImGuiKey_DownArrow] = GLFW_KEY_DOWN;
        io.KeyMap[ImGuiKey_Home] = GLFW_KEY_HOME;
        io.KeyMap[ImGuiKey_End] = GLFW_KEY_END;
        io.KeyMap[ImGuiKey_Delete] = GLFW_KEY_DELETE;
        io.KeyMap[ImGuiKey_Backspace] = GLFW_KEY_BACKSPACE;
        io.KeyMap[ImGuiKey_Enter] = GLFW_KEY_ENTER;
        io.KeyMap[ImGuiKey_Escape] = GLFW_KEY_ESCAPE;
        io.KeyMap[ImGuiKey_A] = GLFW_KEY_A;
        io.KeyMap[ImGuiKey_C] = GLFW_KEY_C;
        io.KeyMap[ImGuiKey_V] = GLFW_KEY_V;
        io.KeyMap[ImGuiKey_X] = GLFW_KEY_X;
        io.KeyMap[ImGuiKey_Y] = GLFW_KEY_Y;
        io.KeyMap[ImGuiKey_Z] = GLFW_KEY_Z;
              
        io.RenderDrawListsFn = &renderDrawLists;
    }

    ///
    public static @property bool capturesMouse() { return g_capturesMouse; }

    private void OnKeyInput(UEEvent event)
    {
        auto io = ig_GetIO();

        if (UEEvent.KeyEvent.Action.Down == event.keyEvent.action)
            io.KeysDown[event.keyEvent.key] = true;
        if (UEEvent.KeyEvent.Action.Up == event.keyEvent.action)
            io.KeysDown[event.keyEvent.key] = false;

        io.KeyCtrl = event.keyEvent.isModCtrl;
        io.KeyShift = event.keyEvent.isModShift;
        io.KeyAlt = event.keyEvent.isModAlt;
    }

    private void OnCharInput(UEEvent event)
    {
        auto utfchar = cast(uint)event.textEvent.character;

        if (utfchar > 0 && utfchar < 0x10000)
        {
            ImGuiIO_AddInputCharacter(cast(ushort)utfchar);
        }
    }

    private void OnScrollInput(UEEvent event)
    {
        if(event.mouseScrollEvent.yoffset != 0)
        {
            g_MouseWheel += cast(float)event.mouseScrollEvent.yoffset;
        }
    }

    static bool TreeNode(string txt)
    {
        return ig_TreeNode(toStringz(txt));
    }

    static bool TreeNode(const void* pid, string txt)
    {
        return ig_TreeNodePtr(pid, toStringz(txt));
    }

    static bool checkbox(string label, ref bool v)
    {
        return ig_Checkbox(toStringz(label), &v);
    }

    ///
    static bool EnumCombo(T)(string label, ref T v) 
        if(is(T == enum))
    {
        enum enumMembers = __traits(allMembers, T);
        enum enumElemCount = enumMembers.length;

        static string[enumElemCount] enumMemberNames = void;
        foreach(i,enumMember; enumMembers)
            enumMemberNames[i] = enumMember;

        static extern(C) bool getItemText(void* data, int idx, const(char)** outText) nothrow
        {
            *outText = toStringz(enumMemberNames[idx]);
            return true;
        }

        int currentItem = 0;

        import std.traits;
        foreach(i,enumMember; EnumMembers!T)
            if(enumMember == v)
                currentItem = i;

        auto res = ig_Combo3(toStringz(label),&currentItem,&getItemText,null,enumElemCount);

        v = cast(T)currentItem;
        return res;
    }

    static bool InputVec(string label, ref vec3 v)
    {
        static immutable ITEMWIDTH = 80;
        bool res = false;
        ig_Text("%s:",toStringz(label));

        ig_PushIdPtr(v.vector.ptr);
        ig_PushItemWidth(ITEMWIDTH);
        scope(exit)ig_PopItemWidth();
        res = ig_DragFloat("x",&v.vector[0]);
        ig_SameLine();
        ig_PushIdPtr(v.vector.ptr+1);
        res = ig_DragFloat("y",&v.vector[1]) || res;
        ig_SameLine();
        ig_PushIdPtr(v.vector.ptr+2);
        res = ig_DragFloat("z",&v.vector[2]) || res;

        return res;
    }
    
    static void DragFloat(string label, ref float v, float min=-float.infinity, float max=float.infinity)
    {
        ig_DragFloat(toStringz(label),&v,1,min,max);
    }

    static void DragInt(string label, ref int v, int min=int.min, int max=int.max)
    {
        ig_DragInt(toStringz(label),&v,1,min,max);
    }

    static bool InputFloat3(string label, ref float[3] v)
    {
        return ig_InputFloat3(toStringz(label), v, 2);
    }

    static bool InputFloat4(string label, ref float[4] v)
    {
        return ig_InputFloat4(toStringz(label), v, 2);
    }

    static void InputText(int MaxLength=64)(string label, ref string v)
    {
        assert(v.length <= MaxLength);

        static char[MaxLength] buf;

        buf[] = '\0';
        buf[0..v.length] = v[];

        ig_InputText(toStringz(label), buf.ptr, MaxLength);

        import std.c.string:strlen;
        auto newLength = strlen(buf.ptr);

        //note: try to avoid alloc when nothing changed
        if(v.length != newLength || buf[0..v.length] != v)
        {
            v = cast(string)buf[0..newLength].idup;
        }
    }

    static void Text(string txt)
    {
        ig_Text(toStringz(txt));
    }

    static void BulletText(string txt)
    {
        ig_BulletText(toStringz(txt));
    }

    static bool Button(string txt)
    {
        return ig_Button(toStringz(txt));
    }

    static bool Selectable(string txt, bool selected)
    {
        return ig_Selectable(toStringz(txt), selected);
    }

    static bool SmallButton(string txt)
    {
        return ig_SmallButton(toStringz(txt));
    }

    static void startFrame()
    {
        if (!g_FontTexture)
            createDeviceObjects();
        
        auto io = ig_GetIO();
        
        // Setup display size (every frame to accommodate for window resizing)
        int w, h;
        int display_w, display_h;
        glfwGetWindowSize(g_window, &w, &h);
        glfwGetFramebufferSize(g_window, &display_w, &display_h);
        io.DisplaySize = ImVec2(cast(float)display_w, cast(float)display_h);

        // Setup time step
        double current_time =  glfwGetTime();
        io.DeltaTime = g_Time > 0.0 ? cast(float)(current_time - g_Time) : cast(float)(1.0f/60.0f);
        g_Time = current_time;

        // Setup inputs
        // (we already got mouse wheel, keyboard keys & characters from glfw callbacks polled in glfwPollEvents())
        if (glfwGetWindowAttrib(g_window, GLFW_FOCUSED))
        {
            double mouse_x, mouse_y;
            glfwGetCursorPos(g_window, &mouse_x, &mouse_y);
            mouse_x *= cast(float)display_w / w;                        // Convert mouse coordinates to pixels
            mouse_y *= cast(float)display_h / h;
            io.MousePos = ImVec2(mouse_x, mouse_y);   // Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
        }
        else
        {
            io.MousePos = ImVec2(-1,-1);
        }
        
        for (int i = 0; i < 3; i++)
        {
            // If a mouse press event came, always pass it as "mouse held this frame", 
            // so we don't miss click-release events that are shorter than 1 frame.
            io.MouseDown[i] = g_MousePressed[i] || glfwGetMouseButton(g_window, i) != 0;    
            g_MousePressed[i] = false;
        }
        
        io.MouseWheel = g_MouseWheel;
        g_MouseWheel = 0.0f;

        ig_NewFrame();

        g_capturesMouse = io.WantCaptureMouse;
    }

    static void renderGUI()
    {
        ig_Render();
    }

private:
    static GLFWwindow*  g_window;
    static double       g_Time = 0.0f;
    static bool[3]      g_MousePressed;
    static double       g_MouseWheel = 0.0f;
    static GLuint       g_FontTexture = 0;
    static int          g_ShaderHandle = 0, g_VertHandle = 0, g_FragHandle = 0;
    static int          g_AttribLocationTex = 0, g_AttribLocationProjMtx = 0;
    static int          g_AttribLocationPosition = 0, g_AttribLocationUV = 0, g_AttribLocationColor = 0;
    static size_t       g_VboMaxSize = 20000;
    static uint         g_VboHandle, g_VaoHandle;
    static bool         g_capturesMouse;

    static extern(C) nothrow 
    void renderDrawLists(ImDrawList** cmd_lists, int count)
    {
        if (count == 0)
            return;
        
        import std.stdio;
        
        // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled
        glEnable(GL_BLEND);
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_CULL_FACE);
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_SCISSOR_TEST);
        glActiveTexture(GL_TEXTURE0);
        
        auto io = ig_GetIO();
        // Setup orthographic projection matrix
        const float width = io.DisplaySize.x;
        const float height = io.DisplaySize.y;
        const float[4][4] ortho_projection =
        [
            [ 2.0f/width,   0.0f,           0.0f,       0.0f ],
            [ 0.0f,         2.0f/-height,   0.0f,       0.0f ],
            [ 0.0f,         0.0f,           -1.0f,      0.0f ],
            [ -1.0f,        1.0f,           0.0f,       1.0f ],
        ];
        glUseProgram(g_ShaderHandle);
        glUniform1i(g_AttribLocationTex, 0);
        glUniformMatrix4fv(g_AttribLocationProjMtx, 1, GL_FALSE, &ortho_projection[0][0]);
        
        // Grow our buffer according to what we need
        size_t total_vtx_count = 0;
        for (int n = 0; n < count; n++)
        {
            total_vtx_count += ImDrawList_GetVertexBufferSize(cmd_lists[n]);
        }
        //try writefln("cnt: %s",total_vtx_count); catch{}
        
        glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
        size_t neededBufferSize = total_vtx_count * ImDrawVert.sizeof;
        if (neededBufferSize > g_VboMaxSize)
        {
            g_VboMaxSize = neededBufferSize + 5000;  // Grow buffer
            glBufferData(GL_ARRAY_BUFFER, g_VboMaxSize, null, GL_STREAM_DRAW);
        }
        
        // Copy and convert all vertices into a single contiguous buffer
        ubyte* buffer_data = cast(ubyte*)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
        if (!buffer_data)
            return;
        
        for (int n = 0; n < count; n++)
        {
            ImDrawList* cmd_list = cmd_lists[n];
            auto vListSize = ImDrawList_GetVertexBufferSize(cmd_list) * ImDrawVert.sizeof;
            import std.c.string:memcpy;
            memcpy(buffer_data, ImDrawList_GetVertexPtr(cmd_list,0), vListSize);
            buffer_data += vListSize;
        }
        glUnmapBuffer(GL_ARRAY_BUFFER);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(g_VaoHandle);
        
        int cmd_offset = 0;
        for (int n = 0; n < count; n++)
        {
            ImDrawList* cmd_list = cmd_lists[n];
            int vtx_offset = cmd_offset;
            
            auto cmdCnt = ImDrawList_GetCmdSize(cmd_list);
            
            foreach(i; 0..cmdCnt)
            {
                auto pcmd = ImDrawList_GetCmdPtr(cmd_list, i);
                
                if (pcmd.user_callback)
                {
                    pcmd.user_callback(cmd_list, pcmd);
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, cast(GLuint)pcmd.texture_id);
                    glScissor(cast(int)pcmd.clip_rect.x, cast(int)(height - pcmd.clip_rect.w), cast(int)(pcmd.clip_rect.z - pcmd.clip_rect.x), cast(int)(pcmd.clip_rect.w - pcmd.clip_rect.y));
                    glDrawArrays(GL_TRIANGLES, vtx_offset, pcmd.vtx_count);
                }
                vtx_offset += pcmd.vtx_count;
            }
            
            cmd_offset = vtx_offset;
        }
        
        // Restore modified state
        glBindVertexArray(0);
        glUseProgram(0);
        glDisable(GL_SCISSOR_TEST);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    static void createDeviceObjects()
    {
        const GLchar *vertex_shader =
            "#version 330\n"
                "uniform mat4 ProjMtx;\n"
                "in vec2 Position;\n"
                "in vec2 UV;\n"
                "in vec4 Color;\n"
                "out vec2 Frag_UV;\n"
                "out vec4 Frag_Color;\n"
                "void main()\n"
                "{\n"
                "   Frag_UV = UV;\n"
                "   Frag_Color = Color;\n"
                "   gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
                "}\n";
        
        const GLchar* fragment_shader =
            "#version 330\n"
                "uniform sampler2D Texture;\n"
                "in vec2 Frag_UV;\n"
                "in vec4 Frag_Color;\n"
                "out vec4 Out_Color;\n"
                "void main()\n"
                "{\n"
                "   Out_Color = Frag_Color * texture( Texture, Frag_UV.st);\n"
                "}\n";
        
        g_ShaderHandle = glCreateProgram();
        g_VertHandle = glCreateShader(GL_VERTEX_SHADER);
        g_FragHandle = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(g_VertHandle, 1, &vertex_shader, null);
        glShaderSource(g_FragHandle, 1, &fragment_shader, null);
        glCompileShader(g_VertHandle);
        glCompileShader(g_FragHandle);
        glAttachShader(g_ShaderHandle, g_VertHandle);
        glAttachShader(g_ShaderHandle, g_FragHandle);
        glLinkProgram(g_ShaderHandle);
        
        g_AttribLocationTex = glGetUniformLocation(g_ShaderHandle, "Texture");
        g_AttribLocationProjMtx = glGetUniformLocation(g_ShaderHandle, "ProjMtx");
        g_AttribLocationPosition = glGetAttribLocation(g_ShaderHandle, "Position");
        g_AttribLocationUV = glGetAttribLocation(g_ShaderHandle, "UV");
        g_AttribLocationColor = glGetAttribLocation(g_ShaderHandle, "Color");
        
        glGenBuffers(1, &g_VboHandle);
        glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
        glBufferData(GL_ARRAY_BUFFER, g_VboMaxSize, null, GL_DYNAMIC_DRAW);
        
        glGenVertexArrays(1, &g_VaoHandle);
        glBindVertexArray(g_VaoHandle);
        glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
        glEnableVertexAttribArray(g_AttribLocationPosition);
        glEnableVertexAttribArray(g_AttribLocationUV);
        glEnableVertexAttribArray(g_AttribLocationColor);
        
        glVertexAttribPointer(g_AttribLocationPosition, 2, GL_FLOAT, GL_FALSE, ImDrawVert.sizeof, cast(void*)0);
        glVertexAttribPointer(g_AttribLocationUV, 2, GL_FLOAT, GL_FALSE, ImDrawVert.sizeof, cast(void*)ImDrawVert.uv.offsetof);
        glVertexAttribPointer(g_AttribLocationColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, ImDrawVert.sizeof, cast(void*)ImDrawVert.col.offsetof);
        
        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        createFontsTexture();
    }

    static void createFontsTexture()
    {
        ImGuiIO* io = ig_GetIO();
        
        ubyte* pixels;
        int width, height;
        ImFontAtlas_GetTexDataAsRGBA32(io.Fonts,&pixels,&width,&height,null);
        
        glGenTextures(1, &g_FontTexture);
        glBindTexture(GL_TEXTURE_2D, g_FontTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        
        // Store our identifier
        ImFontAtlas_SetTexID(io.Fonts, cast(void*)g_FontTexture);
    }
}