
string HG_TypeToExpandedName(float t) {
    switch(t) {
        case HG_NORMAL      :   return "Hand Grenade";
        case HG_NAPALM      :   return "Napalm Grenade";
        case HG_REMOTE      :   return "Fire Trap";
        case HG_PLASMA      :   return "Plasma Bomb";
        case HG_PLASMA_SHARD:   return "Plasma Bomb";
        case HG_TRANSLOC    :   return "Translocator";
        case HG_SHIELD      :   return "Reflective Shield";
        case HG_LINKER      :   return "Linking Shell";
        case HG_GG          :   return "GG Button";
        case HG_LASER       :   return "Lasergun";
        case HG_CLOAK       :   return "Concealing Cloak";
        case HG_RANDOM      :   return "Random Nadget";
        default             :   return "Fuckoff Grenade";
    }
}

string HG_TypeToName(float t) {
    switch(t) {
        case HG_NORMAL      :   return "normal";
        case HG_NAPALM      :   return "napalm";
        case HG_REMOTE      :   return "remote";
        case HG_PLASMA      :   return "plasma";
        case HG_TRANSLOC    :   return "transloc";
        case HG_SHIELD      :   return "shield";
        case HG_LINKER      :   return "linker";
        case HG_GG          :   return "gg";
        case HG_LASER       :   return "laser";
        case HG_CLOAK       :   return "cloak";
        case HG_RANDOM      :   return "random";
        default             :   return strcat("fuckoff", ftos(t));
    }
}

float HG_NameToType(string t) {
    switch(t) {
        case "napalm"       :   return HG_NAPALM;
        case "remote"       :   return HG_REMOTE;
        case "plasma"       :   return HG_PLASMA;
        case "transloc"     :   return HG_TRANSLOC;
        case "shield"       :   return HG_SHIELD;
        case "linker"       :   return HG_LINKER;
        case "gg"           :   return HG_GG;
        case "laser"        :   return HG_LASER;
        case "cloak"        :   return HG_CLOAK;
        case "random"       :   return HG_RANDOM;
        default             :   return HG_NORMAL;
    }
}

string HG_NameToExpandedName(string t) {
    return HG_TypeToExpandedName(HG_NameToType(t));
}

vector HG_TypeToColor(float t) {
    switch(t) {
        case HG_NORMAL      :   return '0.2 1.0 0.2';
        case HG_NAPALM      :   return '1.0 0.5 0.0';
        case HG_REMOTE      :   return '1.0 0.3 0.3';
        case HG_PLASMA      :   return '0.1 1.0 1.0';
        case HG_TRANSLOC    :   return '1.0 0.3 0.9';
        case HG_SHIELD      :   return '1.0 1.0 0.0';
        case HG_LINKER      :   return '0.5 0.5 1.0';
        case HG_LASER       :   return '1.0 0.5 0.0';   // TODO: unique color for this?
        case HG_CLOAK       :   return '0.7 0.7 0.7';
        case HG_GG          :   return '0.5 0.5 0.5' + colormapPaletteColor(15, FALSE);
        case HG_RANDOM      :   return '1.0 1.0 1.0';
        default             :   return '0.5 0.5 0.5';
    }
}

string HG_NameToIcon(string n, float large, float alt) {
    string s = strcat("gfx/nades/", n);
    
    if(large)   s = strcat(s, "_large");
    if(alt)     s = strcat(s, "_alt");
    
    return s;
}

string HG_TypeToIcon(float t, float large, float alt) {
    return HG_NameToIcon(HG_TypeToName(t), large, alt);
}
