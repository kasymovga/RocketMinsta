
void IP2C_SetCountry_Internal(entity player, string cn) {
    if(player.hidecountry || cn == "")
        cn = "xx";
    
    if(IP_IS_WEEABOO(player.netaddress)) if(substring(player.netname, 0, 2) == "^0")
        cn = "pi";
    
    if(player.ip2c_country)
        strunzone(player.ip2c_country);
    
    player.ip2c_country = strzone(cn);
    
    if(player.scorekeeper) {
        cn = strtolower(cn);  // flag icons have lowcase names
        PlayerScore_Set(player, SP_COUNTRY, str2chr(substring(cn, 0, 1), 0) | (str2chr(substring(cn, 1, 1), 0) * 256));
    } else
        IP2C_Log(strcat(player.netname, "^7 has no scorekeeper"));
}

void IP2C_LookupForPlayer_Callback(string ip, string cn, entity player) {
    entity e;
    FOR_EACH_REALCLIENT(e) if(e.netaddress == ip)
        IP2C_SetCountry_Internal(e, cn);
}

void IP2C_SetCountry(entity player) {
    if(clienttype(player) != CLIENTTYPE_REAL)
        IP2C_SetCountry_Internal(player, "");
    else
        IP2C_Lookup(player.netaddress, IP2C_LookupForPlayer_Callback, 0, player);
}
