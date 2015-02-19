module unecht.core.entity;

import gl3n.linalg:vec3;

import unecht;

class Entity
{
	vec3 position;
	vec3 scale;
	
	void addComponent(T)()
	{
		auto newt = new T();
		newt.setEntity(this);
		
		components ~= newt;
	}
	
	void addComponent(string _type)
	{
		auto newcomp = cast(Component)Object.factory(_type);
		assert(newcomp);
		
		newcomp.setEntity(this);
		
		newcomp.onCreate();
		
		components ~= newcomp;
	}
	
	static auto create()
	{
		return new Entity();
	}
	
private:
	Entity parent;
	Entity[] children;
	
	Component[] components;
}