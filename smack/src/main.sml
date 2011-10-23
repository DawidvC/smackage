structure Smack =
struct
    exception SmackExn of string

    (** Attempt to ascertain the smackage home directory.
        Resolved in this order:

        SMACKAGE_HOME environment variable
        ~/.smackage/
        /usr/local/smackage/
        /opt/smackage/
    *)
    val smackHome =
    let
        fun tryDir (SOME s) = ((OS.FileSys.openDir s; true) handle _ => false)
          | tryDir NONE = false
        val envHome = OS.Process.getEnv "SMACKAGE_HOME"
        val envHome' = if OS.Process.getEnv "HOME" = NONE 
            then NONE 
            else SOME (valOf (OS.Process.getEnv "HOME") ^ "/.smackage")
    in
        if tryDir envHome then valOf envHome else
        if tryDir envHome' then valOf envHome' else
        if tryDir (SOME "/usr/local/smackage") then "/usr/local/smackage" else
        if tryDir (SOME "/opt/smackage") then "/opt/smackage" else
        raise SmackExn "Cannot find smackage home. Try setting SMACKAGE_HOME"
    end

    (** Install a package with a given name and version.
        An empty version string means "the latest version".
        raises SmackExn in the event that the package is already installed or
        if no such package or version is found. *)
    fun install name version =
    let
        val _ = VersionIndex.loadVersions smackHome
        val _ = if version = "" then 
                    raise Fail "Install needs an explicit version for now."
                else ()
        val ver = SemVer.fromString version
        val _ = SmackLib.install smackHome (name,ver)
        val _ = print "Candidates:\n"
        val candidates = VersionIndex.queryVersions name
        val _ = List.app 
            (fn (n,v,p) => print (n ^ " " ^ SemVer.toString v ^ "\n")) 
                candidates
        val _ = SmackLib.install (!Configure.smackHome) (name,ver)
    in
        ()
    end

    (** Uninstall a package with a given name and version.
        An empty version string means "all versions".
        raises SmackExn in the event that the package is already installed or
        if no such package or version is found. *)
    fun uninstall name version =
    let
        val _ = ()
    in
        raise SmackExn "Not implemented"
    end

    (** List the packages currently installed. *)
    fun listInstalled () = raise SmackExn "Not implemented"

    (** Search for a package in the index, with an optional version *)
    fun search name version = raise SmackExn "Not implemented"

    (** Display metadata for a given package, plus installed status *)
    fun info name version = raise SmackExn "Not implemented"

    fun update () = raise SmackExn "Not implemented"

    fun modsource pkg maybe_prot =  
       let 
          val sourcesLocal = 
             OS.Path.joinDirFile { dir = !Configure.smackHome
                                 , file = "sources.local"}
          val file = TextIO.openIn sourcesLocal

          fun getLine () = 
             case Option.map 
                    (String.tokens Char.isSpace) 
                    (TextIO.inputLine file) of              
                NONE => NONE
              | SOME [] => getLine ()
              | SOME [ pkg', prot', uri' ] =>
                   SOME (pkg', Protocol.fromString (prot' ^ " " ^ uri'))
              | SOME s => raise Fail ( "Bad source line: " 
                                     ^ String.concatWith " " s)

          fun notfound () =
             raise SmackExn ( "Could not find source spec for `" ^ pkg 
                            ^ "` in sources.local to delete it")

          fun read_big accum = 
             case getLine () of 
                NONE => List.rev accum
              | SOME line => read_big (line :: accum)

          fun read_small accum = 
             case getLine () of
                NONE => 
                (case maybe_prot of 
                    NONE => notfound ()
                  | SOME prot => List.rev ((pkg, prot) :: accum))
              | SOME (pkg', prot') => 
                (case String.compare (pkg, pkg') of
                    LESS => 
                    (case maybe_prot of 
                        NONE => notfound ()
                      | SOME prot => 
                           read_big ((pkg', prot') :: (pkg, prot) :: accum))
                  | EQUAL => 
                    (case maybe_prot of 
                        NONE =>  
                           ( print ("Deleting source spec " ^ pkg ^ "...\n")
                           ; read_big accum)
                      | SOME prot => 
                           ( print ("WARNING: overwriting source spec\n\
                                \OLD: " ^ pkg' ^ Protocol.toString prot' ^ "\n\
                                \NEW: " ^ pkg ^ Protocol.toString prot ^ "\n")
                           ; read_big ((pkg, prot) :: accum)))
                  | GREATER => read_small ((pkg', prot') :: accum))

          val sources = read_small []

          val file = TextIO.openOut sourcesLocal

          fun write [] = TextIO.closeOut file
            | write ((pkg, prot) :: sources) = 
              ( TextIO.output (file, pkg ^ " " ^ Protocol.toString prot ^ "\n")
              ; write sources)
       in
          write sources; print "Done rewriting sources.local.\n"
       end

    fun printUsage () =
        (print "Usage: smackage <command> [args]\n";
         print " Commands:\n";
         print "\thelp\t\t\t\tDisplay this usage and exit\n";
         print "\tinfo <name> [version]\t\tDisplay package information.\n";
         print "\tinstall <name> [version]\tInstall the named package\n";
         print "\tlist\t\t\t\tList installed packages\n";
         print "\trefresh\t\t\t\tRefresh the versions.smackspec index\n";
         print "\tsearch <name>\t\t\tFind an appropriate package\n";
         print "\tsource <name> <protocol> <url>\tAdd a smackage source to sources.local\n";
         print "\tunsource <name>\t\t\tRemove a smackage source from sources.local\n";
         print "\tuninstall <name> [version]\tRemove a package\n";
         print "\tupdate\t\t\t\tUpdate the package database\n");

    fun main args = 
       let
          val () = Configure.init ()
       in
          case args of
             ("--help"::_) => (printUsage(); OS.Process.success)
           | ("-h"::_) => (printUsage(); OS.Process.success)
           | ("help"::_) => (printUsage(); OS.Process.success)
           | ["info",pkg,ver] => (info pkg ver; OS.Process.success)
           | ["info",pkg] => (info pkg ""; OS.Process.success)
           | ["update"] => (update (); OS.Process.success)
           | ["search",pkg] => (search pkg ""; OS.Process.success)
           | ["search",pkg,ver] => (search pkg ver; OS.Process.success)
           | ["source",pkg,prot,url] => 
                ( modsource pkg (SOME (Protocol.fromString (prot ^ " " ^ url)))
                ; OS.Process.success)
           | ["unsource",pkg] => 
                ( modsource pkg NONE
                ; OS.Process.success)
           | ["refresh"] => (OS.Process.success)
           | ["install",pkg,ver] => (install pkg ver; OS.Process.success)
           | ["install",pkg] => (install pkg ""; OS.Process.success)
           | ["uninstall",pkg,ver] => (uninstall pkg ver; OS.Process.success)
           | ["uninstall",pkg] => (uninstall pkg ""; OS.Process.success)
           | ["list"] => (listInstalled(); OS.Process.success)
           | _ => (printUsage(); OS.Process.failure)
       end handle (SmackExn s) => 
           (TextIO.output (TextIO.stdErr, s ^ "\n"); OS.Process.failure)
                | (Fail s) => 
           (TextIO.output (TextIO.stdErr, s ^ "\n"); OS.Process.failure)
end


