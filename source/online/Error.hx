package online;

typedef Error = #if (colyseus < "0.15.3") io.colyseus.error.MatchMakeError #else io.colyseus.error.HttpException #end