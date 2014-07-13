float IPCacheDB;
.entity ip2c_callbackentity;
.string ip2c_callbackip;
.ip2c_callback_t ip2c_callbackfunction;
.float ip2c_requested_at;

void IP2C_Log(string msg) {
    #ifdef MENUQC
        print("MENU ");
    #endif
    
    print("IP2C: ", msg, "\n");
}

void IP2C_FreeCallbackEntity(entity e) {
    if(e.ip2c_callbackip)
        strunzone(e.ip2c_callbackip);
        
    remove(e);
}

void IP2C_Init(void) {
    IP2C_REGISTERVARS()
    IP2C_Log("Loading cached IPs");
    IPCacheDB = db_load(IP2C_DBNAME);
}

void IP2C_Shutdown(void) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
        IP2C_FreeCallbackEntity(e);
    
    IP2C_Log("Saving cached IPs");
    db_save(IPCacheDB, IP2C_DBNAME);
    db_close(IPCacheDB);
}

void IP2C_ClearCache(void) {
    db_close(IPCacheDB);
    IPCacheDB = db_create();
    db_save(IPCacheDB, IP2C_DBNAME);
    
    IP2C_Log("Cleared the cache");
}

string IP2C_LookupCached(string ip) {
    if(IP_IS_WEEABOO(ip))
        return GRORIOUS_NIPPON;
    return db_get(IPCacheDB, ip);
}

void IP2C_CacheIP(string ip, string cn) {
    IP2C_Log(strcat("Cached IP ", ip, ", CN: ", cn));
    db_put(IPCacheDB, ip, cn);
}

void IP2C_RequestTimeout(void) {
    IP2C_Log(strcat("Request for ", self.ip2c_callbackip, " timed out after ", ftos(time - self.ip2c_requested_at), " seconds"));
    self.ip2c_callbackfunction(self.ip2c_callbackip, "", self.ip2c_callbackentity);
    IP2C_FreeCallbackEntity(self);
}

#ifdef MENUQC
.void() think;
.float nextthink;

// apparently menuqc doesn't support thinkfunctions
void IP2C_CheckTimedOut(void) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); ) if(time >= e.nextthink) {
        entity oldself;
        oldself = self;
        self = e;
        e.think();
        self = oldself;
    }
}
#endif

void IP2C_AddCallback(string ip, ip2c_callback_t callback, float timeout, entity callbackentity) {
    if(timeout <= 0)
        timeout = cvar("sv_ip2country_timeout");
    
    entity cb = spawn();
    cb.classname = "ip2c_callbackprovider";
    cb.ip2c_callbackip = strzone(ip);
    cb.ip2c_callbackentity = callbackentity;
    cb.ip2c_callbackfunction = callback;
    cb.think = IP2C_RequestTimeout;
    cb.nextthink = time + timeout;
    cb.ip2c_requested_at = time;
}

void IP2C_ExecCallbacks(string ip, string cn) {
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
    if(e.ip2c_callbackip == ip) {
        e.ip2c_callbackfunction(ip, cn, e.ip2c_callbackentity);
        IP2C_FreeCallbackEntity(e);
    }
}

void IP2C_Lookup(string ip, ip2c_callback_t callback, float timeout, entity callbackentity) {
    if(!cvar("sv_ip2country"))
        return;

    string res;
    res = IP2C_LookupCached(ip);
    
    IP2C_AddCallback(ip, callback, timeout, callbackentity);
    
    if(res != "") {
        IP2C_ExecCallbacks(ip, res);
        return;
    }
    
    if(cvar_string("sv_ip2country_server") == "") {
        IP2C_Log(strcat("Can't lookup ip ", ip, ", sv_ip2country_server is not set"));
        return;
    }
    
    IP2C_Log(strcat("IP ", ip, " is not cached, requesting from the server"));
    uri_get(strcat(cvar_string("sv_ip2country_server"), ip), URI_GET_IP2C);
}

void IP2C_URI_Get_Callback(float id, float status, string data) {
    if(status) {
        IP2C_Log(strcat("IP lookup failed, status: ", ftos(status)));
        return;
    }
    
    float n = tokenizebyseparator(data, " ");
    string cn, ip;
    
    cn = substring(argv(0), 0, 2);
    ip = argv(1);
    
    if(cn == "--") {
        IP2C_Log(strcat("The remote server failed to resolve ", ip));
        IP2C_ExecCallbacks(ip, "");
        return;
    }
    
    IP2C_CacheIP(ip, cn);
    IP2C_ExecCallbacks(ip, cn);
}

void IP2C_Callback_DumpToConsole(string ip, string cn, entity e) {
    if(cn != "")
        IP2C_Log(strcat("Country for IP ", ip, ": ", cn));
}

void IP2C_PrintRequests(void) {
    IP2C_Log("^3Requests in progress:");
    
    entity e;
    for(e = world; (e = find(e, classname, "ip2c_callbackprovider")); )
        IP2C_Log(strcat(e.ip2c_callbackip, " : ^5", ftos(time - e.ip2c_requested_at), "s"));
}

float IP2C_GameCommand(string command) {
    float argc = tokenize_console(command);
    
    switch(argv(0)) {
        case "help":
            print("  ip2c_lookup ipaddress\n");
            print("  ip2c_status\n");
            print("  ip2c_clearcache\n");
            return TRUE;
        
        case "ip2c_lookup":
            IP2C_Lookup(argv(1), IP2C_Callback_DumpToConsole, 0, world);
            return TRUE;
            
        case "ip2c_status":
            IP2C_PrintRequests();
            return TRUE;
        
        case "ip2c_clearcache":
            IP2C_ClearCache();
            return TRUE;
    }
    
    return FALSE;
}
