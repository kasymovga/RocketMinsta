
string Buffs_TypeToName(float buff) {
    switch(buff) {
        case BUFF_ARC       :      return "arc";
        case BUFF_SUPPLY    :      return "supply";
        case BUFF_GUARD     :      return "guard";
        case BUFF_HASTE     :      return "haste";
        case BUFF_MEDIC     :      return "medic";
        case BUFF_BASH      :      return "bash";
        case BUFF_VAMPIRE   :      return "vampire";
        case BUFF_TENACITY  :      return "tenacity";
        case BUFF_WRATH     :      return "wrath";
        case BUFF_ANGEL     :      return "angel";
        case BUFF_ADEPT     :      return "adept";
        case BUFF_VISION     :      return "vision";
        case BUFF_NINJA     :      return "ninja";
        case BUFF_ZEN     :      return "zen";

        default             :      return "unknown";
    }
}

float Buffs_NameToType(string name) {
    switch(name) {
        case "arc"          :      return BUFF_ARC;
        case "supply"       :      return BUFF_SUPPLY;
        case "guard"        :      return BUFF_GUARD;
        case "haste"        :      return BUFF_HASTE;
        case "medic"        :      return BUFF_MEDIC;
        case "bash"         :      return BUFF_BASH;
        case "vampire"      :      return BUFF_VAMPIRE;
        case "tenacity"     :      return BUFF_TENACITY;
        case "wrath"        :      return BUFF_WRATH;
        case "angel"        :      return BUFF_ANGEL;
        case "adept"        :      return BUFF_ADEPT;
        case "vision"       :      return BUFF_VISION;
        case "ninja"        :      return BUFF_NINJA; 
        case "zen"          :      return BUFF_ZEN;

        default             :      return 0;
    }
}

string Buffs_TypeToExpandedName(float buff) {
    switch(buff) {
        case BUFF_ARC       :      return "Arc";
        case BUFF_SUPPLY    :      return "Supply";
        case BUFF_GUARD     :      return "Guard";
        case BUFF_HASTE     :      return "Haste";
        case BUFF_MEDIC     :      return "Medic";
        case BUFF_BASH      :      return "Bash";
        case BUFF_VAMPIRE   :      return "Vampire";
        case BUFF_TENACITY  :      return "Tenacity";
        case BUFF_WRATH     :      return "Wrath";
	case BUFF_ANGEL     :      return "Angel";
        case BUFF_ADEPT     :      return "Adept";
        case BUFF_VISION    :      return "Vision";
        case BUFF_NINJA     :      return "Ninja";
        case BUFF_ZEN       :      return "Zen"; 

        default             :      return "Unknown";
    }
}

string Buffs_NameToExpandedName(string t) {
    return Buffs_TypeToExpandedName(Buffs_NameToType(t));
}

vector Buffs_TypeToColor(float buff) {
    switch(buff) {
        case BUFF_ARC       :      return '0.20  0.70  1.00';    // Cyan
        case BUFF_SUPPLY    :      return '0.20  1.00  0.20';    // Green
        case BUFF_GUARD     :      return '0.30  0.20  1.00';    // Dark Blue
        case BUFF_HASTE     :      return '1.00  1.00  0.20';    // Yellow
        case BUFF_MEDIC     :      return '1.00  0.30  1.00';    // Pink
        case BUFF_BASH      :      return '1.00  0.40  0.00';    // Orange
        case BUFF_VAMPIRE   :      return '1.00  0.15  0.00';    // Scarlet
        case BUFF_TENACITY  :      return '0.66  0.66  0.73';    // Silver
        case BUFF_WRATH     :      return '0.55  0.50  1.00';    // Bright Blue
        case BUFF_ANGEL     :      return '0.90  0.90  0.40';    // Bright Yellow
        case BUFF_ADEPT     :      return '0.57  0.00  1.00';    // Viole(n)t
        case BUFF_VISION    :      return '0.29  0.29  0.29';    // White ish
        case BUFF_NINJA     :      return '0.30  0.10  0.20';    // Purple ish
        case BUFF_ZEN       :      return '0.40  1.00  0.40';    // Bright green

        default             :      return '0.00  0.00  0.00';
    }
}

float Buffs_TypeToIndex(float buff) {
    float b, i;
    for(b = BUFF_FIRST; b <= BUFF_LAST; b *= 2, ++i)
        if(buff == b)
            return i;
    return -1;
}
