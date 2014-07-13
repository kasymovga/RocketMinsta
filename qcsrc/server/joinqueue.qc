
entity jq_first;
entity jq_last;
.entity jq_next;
.entity jq_prev;

entity JoinQ_Pop(void) {
    if(!jq_first)
        return world;
    
    if(gameover)
        return world;
    
    if(!isJoinAllowed())
        return world;
    
    entity o, s = self;
    self = s = jq_first;
    
    JoinQ_Remove(self);
    LeaveSpectatorMode();
    
    self = o;
    return s;
}

void JoinQ_Push(entity plr) {
    if(plr.joinqueue)
        error("Attempted to queue an already queued player");
    
    if(jq_last) {
        plr.jq_prev = jq_last;
        jq_last.jq_next = plr;
    } else
        jq_first = plr;
    
    plr.jq_next = world;
    jq_last = plr;
    
    bprint("^4", plr.netname, "^4 has been queued for the game\n");
    
    JoinQ_Fix();
}

void JoinQ_Remove(entity plr) {
    if(plr == jq_first)
        jq_first = jq_first.jq_next;
    
    if(plr == jq_last)
        jq_last = plr.jq_prev;
    
    if(plr.jq_prev)
        plr.jq_prev.jq_next = plr.jq_next;
    
    if(plr.jq_next)
        plr.jq_next.jq_prev = plr.jq_prev;
    
    if(plr.joinqueue)
        bprint("^4", plr.netname, "^4 has been removed from the join queue\n");
    
    plr.jq_next = plr.jq_prev = world;
    plr.joinqueue = 0;

    if(plr.scorekeeper)
        PlayerScore_Set(plr, SP_QUEUE, 0);
    
    JoinQ_Fix();
}

void JoinQ_Fix(void) {
    entity e; 
    float i;
    
    for(e = jq_first, i = 1; e; e = e.jq_next, ++i) {
        e.joinqueue = i;
        if(e.scorekeeper)
            PlayerScore_Set(e, SP_QUEUE, e.joinqueue);
    }
}
