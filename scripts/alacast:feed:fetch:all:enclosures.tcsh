#!/bin/tcsh -f

init:
	if(! ${?0} ) then
		set status=-1;
		printf "This script cannot be sourced; only executed.\n" > /dev/stdout;
		goto usage;
	endif
	
	onintr exit_script;
	
	set scripts_basename="`basename '${0}'`";
	
	set argc=${#argv};
	if( ${argc} < 1 ) then
		set status=-1;
		goto usage;
	endif
	
	if( "`alias cwdcmd`" != "" ) then
		set oldcwdcmd="`alias cwdcmd`";
		unalias cwdcmd;
	endif
	
	set old_owd="${cwd}";
	cd "`dirname '${0}'`";
	set scripts_path="${cwd}";
	cd "${owd}";
	set owd="${old_owd}";
	unset old_owd;
	
	set script="${scripts_path}/${scripts_basename}";
	
	set escaped_cwd="`printf "\""%s"\"" "\""${cwd}"\"" | sed -r 's/\//\\\//g' | sed -r 's/(["\""])/"\""\\"\"""\""/g' | sed -r 's/([*])/\\\1/g' | sed -r 's/(['\!'])/\\\1/g'`";
	set escaped_home_dir="`printf "\""%s"\"" "\""${HOME}"\"" | sed -r 's/\//\\\//g' | sed -r 's/(["\""])/"\""\\"\"""\""/g' | sed -r 's/([*])/\\\1/g' | sed -r 's/(['\!'])/\\\1/g'`";
	
	alias ex "ex -E -n -X --noplugin";
	
	#set download_command="curl";
	#set download_command_with_options="${download_command} --location --fail --show-error --silent --output";
	
	set download_command="wget";
	set download_command_with_options="${download_command} --no-check-certificate --quiet --continue --output-document";
	
	alias ${download_command} "${download_command_with_options}";
	
	set status=0;
	set logging;
	
	set alacasts_download_log="`mktemp --tmpdir alacast:feeds:list.XXXXXX`";
	
	set downloading;
	
	goto parse_argv;
#init:

main:
	if(! -e "${alacasts_download_log}" ) then
		set status=-1;
		goto usage;
	endif
	
	if(! ${?save_to_dir} ) then
		if( "`basename '${0}' | sed -r 's/^(alacast).*/\1/ig'`" == "alacast" ) then
			if( -e "${HOME}/.alacast/alacast.ini" ) then
				set alacast_ini="${HOME}/.alacast/alacast.ini";
			else if( -e "${HOME}/.alacast/profiles/${USER}/alacast.ini" ) then
				set alacast_ini="${HOME}/.alacast/profiles/${USER}/alacast.ini";
			else if( -e "`dirname '${0}'`../data/profiles/${USER}/alacast.ini" ) then
				set alacast_ini="`dirname '${0}'`../data/profiles/${USER}/alacast.ini";
			else if( -e "`dirname '${0}'`../data/profiles/default/alacast.ini" ) then
				set alacast_ini="`dirname '${0}'`../data/profiles/default/alacast.ini";
			endif
			if( ${?alacast_ini} ) then
				set media_dir="`/bin/grep --perl-regexp '^media_dir.*' '${alacast_ini}' | /bin/sed -r 's/.*[^=]*=["\""'\'']([^"\""'\'']*)["\""'\''];/\1/' | sed -r 's/\//\\\//g'`";
				set save_to_dir="`/bin/grep --perl-regexp '^save_to_dir.*' '${alacast_ini}' | /bin/sed -r 's/.*[^=]*=["\""'\'']([^"\""'\'']*)["\""'\''];/\1/' | sed -r 's/\{media_dir\}/${media_dir}/g'`";
				unset alacast_ini media_dir;
			endif
		endif
	endif

	if( ${?save_to_dir} ) then
		if( "${save_to_dir}" != "${cwd}" ) then
			if(! -d "${save_to_dir}" ) \
				mkdir -p "${save_to_dir}";
			set starting_old_owd="${owd}";
			cd "${save_to_dir}";
		endif
		unset save_to_dir;
	endif
	
	set noglob;
	
	set please_wait_phrase="...please be patient, I may need several moments.\t\t";
	
	if(! ${?logging} ) then
		set download_log=/dev/null;
	else
		set download_log="./00-"`basename "${0}"`".log";
		touch "${download_log}";
	endif
	
	if(! ${?silent} ) then
		set output=/dev/stdout;
	else
		set output=/dev/null;
	endif
	
	if( "`alias cwdcmd`" != "" ) then
		set old_cwdcmd="`alias cwdcmd`";
		unalias cwdcmd;
	endif
#main:


fetch_podcasts:
	if( ${?feed} ) then
		printf "Cancelled downloading %s\n" "${feed}";
		
		if(! ${?diagnostic_mode} ) then
			if( -e './00-titles.lst' ) \
				/bin/rm -f './00-titles.lst';
			if( -e './00-enclosures.lst' ) \
				/bin/rm -f './00-enclosures.lst';
			if( -e './00-pubDates.lst' ) \
				/bin/rm -f './00-pubDates.lst';
			if( -e './00-feed.xml' ) \
				/bin/rm -f './00-feed.xml';
		endif
		
		unset feed;
		onintr exit_script;
		sleep 2;
	endif
	
	foreach feed ("`cat "\""${alacasts_download_log}"\""`")
		ex -s '+1d' '+wq!' "${alacasts_download_log}";
		onintr fetch_podcasts;
		set my_feed_xml="`mktemp --tmpdir alacasts.feed.xml.XXXXXX`";
		if(! ${?silent} ) \
			printf "Downloading podcast's feed.\n\t<%s>\n" "${feed}";
		if( ${?logging} ) \
			printf "Downloading podcast's feed.\n\t<%s>\n" "${feed}" >> "${download_log}";
		goto fetch_podcast;
	end
	goto exit_script;
#fetch_podcasts:

fetch_podcast:
	if( ${?title} ) then
		printf "Cancelled downloading %s\n" "${title}";
		
		if(! ${?diagnostic_mode} ) then
			if( -e './00-titles.lst' ) \
				/bin/rm -f './00-titles.lst';
			if( -e './00-enclosures.lst' ) \
				/bin/rm -f './00-enclosures.lst';
			if( -e './00-pubDates.lst' ) \
				/bin/rm -f './00-pubDates.lst';
			if( -e './00-feed.xml' ) \
				/bin/rm -f './00-feed.xml';
		endif
		
		unset feed title;
		if( ${?episodes_filename} ) \
			unset episodes_filename;
		sleep 2;
		goto fetch_podcasts;
	endif
	onintr fetch_podcasts;
	
	if( ! ${?list_episodes} && ! ${?downloading} && ! ${?save_script} ) \
		set downloading;
	
	${download_command_with_options} "${my_feed_xml}" "${feed}";
	
	if(! ${?silent} ) \
		printf "Finding feed's title.\n";
	if( ${?logging} ) \
		printf "Finding feed's title.\n" >> "${download_log}";
	
	#ex -s '+set ff=unix' '+1,$s/\v\r\_$//' '+1,$s/\v\n[ \t]*//' '+1s/\v\>\</\>\r\</g' '+1,$s/\v\<(title|description|pubDate|enclosure)@'\!'.*\>.*\>\n//' '+1,$s/\v^\<[^>]+\>\n//' '+wq!' "${my_feed_xml}";
	ex -s '+set ff=unix' '+1,$s/\v\<\!\-\-.*\-\-\>//' '+1,$s/\v\<\!\[CDATA\[//g' '+1,$s/\v\]\]\>//g' '+1,$s/\v\>[ \t]*\</\>\r\</g' '+1,$s/\v\r\_$//g' '+1,$s/\n//g' '+wq!' "${my_feed_xml}";
	
	if( "`/bin/grep --no-messages --perl-regexp '\r\n\"\$"' "\""${my_feed_xml}"\""`" != "" ) then	
		if(! ${?silent} ) \
			printf "Reformatting Dos feed to Unix format.\n";
		if( ${?logging} ) \
			printf "Reformatting Dos feed to Unix format.\n" >> "${download_log}";
		dos2unix --convmode ASCII "${my_feed_xml}" >& ${output};	
	else if( "`/bin/grep --no-messages --perl-regexp '\r\"\$"' "\""${my_feed_xml}"\""`" != "" ) then	
		if(! ${?silent} ) \
			printf "Reformatting Mac OS feed to Unix format.\n";
		if( ${?logging} ) \
			printf "Reformatting Mac OS feed to Unix format.\n" >> "${download_log}";
		dos2unix --convmode Mac "${my_feed_xml}" >& ${output};
	endif
	
	set title="`cat "\""${my_feed_xml}"\"" | sed -r 's/(\<item\>)/\1\n/g' | head -1 | /bin/grep --no-messages --perl-regexp '\<title[^\>]*\>' | sed -r 's/.*<title[^>]*>([^<]+)<\/title>.*/\1/g' | sed 's/\//\ \-\ /g' | sed -r 's/[\ \t]*\&[^;]+;[\ \t]*/\ /ig' | sed -r 's/^[\ \t]*//g' | sed -r 's/[\ \t]*"\$"//g'`";
	
	if( "${title}" == "" ) then
		if(! ${?silent} ) \
			printf "**error** failed to find feed's title.\n" > /dev/stderr;
		if( ${?logging} ) \
			printf "**error** failed to find feed's title\n" >> "${download_log}";
		
		set status=-1;
		unset feed title;
		goto fetch_podcasts;
	endif
	
	if( "`printf "\""${title}"\"" | sed -r 's/^(The)(.*)"\$"/\1/g'`" == "The" ) \
		set title="`printf "\""${title}"\"" | sed -r 's/^(The)\ (.*)"\$"/\2,\ \1/g'`";
	
	if(! -d "${title}" ) \
		mkdir -p "./${title}";
	set old_owd="${owd}";
	if( "`alias cwdcmd`" != "" ) \
		unalias cwdcmd;
	cd "./${title}";
	
	if( ${?playlist} && ${?playlist_type} ) then
		set playlist="${title}.${playlist_type}";
		playlist:new:create.tcsh "${playlist}";
	endif
	
	if(! ${?silent} ) \
		printf "Preparing to download: %s\n\tTo:\t%s\n" "${title}" "${cwd}";
	if( ${?logging} ) \
		printf "Preparing to download: %s\n\tTo:\t%s\n" "${title}" "${cwd}" >> "${download_log}";
	if(! ${?silent} ) \
		printf "\txmlUrl=\t<%s>\n" "${feed}";
	if( ${?logging} ) \
		printf "\txmlUrl=\t<%s>\n" "${feed}" >> "${download_log}";
	
	if( -e './00-feed.xml' && -e './00-titles.lst' && -e './00-enclosures.lst' && -e './00-pubDates.lst' ) \
		goto continue_download;
	
	# This to make sure we're working with UNIX file types & don't have to repeat newline replacement.
	/bin/cp "${my_feed_xml}" "./00-feed.xml";
	/bin/rm -f "${my_feed_xml}";
	
	# Grabs the titles of the podcast and all episodes.
	if(! ${?silent} ) \
		printf "Finding titles${please_wait_phrase}\t";
	if( ${?logging} ) \
		printf "Finding titles${please_wait_phrase}\t" >> "${download_log}";
	
	# Puts each item, or entry, on its own line:
	ex -s '+1,$s/[\n][\ \t]*//' '+wq!' './00-feed.xml';
	ex -s '+1,$s/[\n][\ \t]*//' '+1,$s/<\/\(item\|entry\)>/\<\/\1\>\r/ig' '+$d' '+wq!' './00-feed.xml';
	
	/bin/cp './00-feed.xml' './00-titles.lst';
	
	ex -s '+1,$s/.*<\(item\|entry\)[^>]*>.*<title[^>]*>\(.*\)<\/title>.*\(enclosure\).*<\/\(item\|entry\)>$/\2/ig' '+1,$s/.*<\(item\|entry\)[^>]*>.*\(enclosure\).*<title[^>]*>\(.*\)<\/title>.*<\/\(item\|entry\)>$/\3/ig' '+1,$s/.*<\(item\|entry\)[^>]*>.*<title[^>]*>\([^<]*\)<\/title>.*<\/\(item\|entry\)>[\n\r]*//ig' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/&\(#038\|amp\)\;/\&/ig' '+1,$s/\v\&(#8220|#8221|quot)\;/\"/ig' '+1,$s/&\(#8243\|#8217\|\#039\|rsquo\|lsquo\)\;/'\''/ig' '+1,$s/&[^;]\+\;[\ \t]*/\ /ig' '+1,$s/#//g' '+1,$s/\//\ \-\ /g' '+wq!' './00-titles.lst';
	if(! ${?silent} ) \
		printf "[done]\n";
	if( ${?logging} ) \
		printf "[done]\n" >> "${download_log}";
	
	# This will be my last update to any part of Alacast v1
	# This fixes episode & chapter titles so that they will sort correctly
	if(! ${?silent} ) \
		printf "Formating titles${please_wait_phrase}";
	if( ${?logging} ) \
		printf "Formating titles${please_wait_phrase}" >> "${download_log}";
	ex -s '+1,$s/^\(Zero\)/0/gi' '+1,$s/^\(One\)/1/gi' '+1,$s/^\(Two\)/2/gi' '+1,$s/^\(Three\)/3/gi' '+1,$s/^\(Four\)/4/gi' '+1,$s/^\(Five\)/5/gi' '+wq!' './00-titles.lst';
	ex -s '+1,$s/^\(Six\)/6/gi' '+1,$s/^\(Seven\)/7/gi' '+1,$s/^\(Eight\)/8/gi' '+1,$s/^\(Nine\)/9/gi' '+1,$s/^\(Ten\)/10/gi' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/^\([0-9]\)ty/\10/gi' '+1,$s/^\(Fifty\)/50/gi' '+1,$s/^\(Thirty\)/30/gi' '+1,$s/^\(Twenty\)/20/gi' '+wq!' './00-titles.lst';
	ex -s '+1,$s/^0\?\([0-9]\)teen/1\1/gi' '+1,$s/^\(Fifteen\)/15/gi' '+1,$s/^\(Thirteen\)/13/gi' '+1,$s/^\(Twelve\)/12/gi' '+1,$s/^\(Eleven\)/11/gi' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/\([^a-zA-Z]\)\(Zero\)/\10/gi' '+1,$s/\([^a-zA-Z]\)\(One\)/\11/gi' '+1,$s/\([^a-zA-Z]\)\(Two\)/\12/gi' '+1,$s/\([^a-zA-Z]\)\(Three\)/\13/gi' '+1,$s/\([^a-zA-Z]\)\(Four\)/\14/gi' '+1,$s/\([^a-zA-Z]\)\(Five\)/\15/gi' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\([^a-zA-Z]\)\(Six\)/\16/gi' '+1,$s/\([^a-zA-Z]\)\(Seven\)/\17/gi' '+1,$s/\([^a-zA-Z]\)\(Eight\)/\18/gi' '+1,$s/\([^a-zA-Z]\)\(Nine\)/\19/gi' '+1,$s/\([^a-zA-Z]\)\(Ten\)/\110/gi' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/\([^a-zA-Z]\)\([0-9]\)ty\([^a-zA-Z]\)/\1\20\3/gi' '+1,$s/\([^a-zA-Z]\)\(Fifty\)\([^a-zA-Z]\)/\150\3/gi' '+1,$s/\([^a-zA-Z]\)\(Thirty\)\([^a-zA-Z]\)/\130\3/gi' '+1,$s/\([^a-zA-Z]\)\(Twenty\)\([^a-zA-Z]\)/\120\3/gi' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\([^a-zA-Z]\)0\?\([0-9]\)teen\([^a-zA-Z]\)/\11\2\3/gi' '+1,$s/\([^a-zA-Z]\)\(Fifteen\)\([^a-zA-Z]\)/\115\3/gi' '+1,$s/\([^a-zA-Z]\)\(Thirteen\)\([^a-zA-Z]\)/\113\3/gi' '+1,$s/\([^a-zA-Z]\)\(Twelve\)\([^a-zA-Z]\)/\112\3/gi' '+1,$s/\([^a-zA-Z]\)\(Eleven\)\([^a-zA-Z]\)/\111\3/gi' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/\([^a-zA-Z]\)\([0-9]\)ty/\1\20/gi' '+1,$s/\([^a-zA-Z]\)\(Fifty\)/\150/gi' '+1,$s/\([^a-zA-Z]\)\(Thirty\)/\130/gi' '+1,$s/\([^a-zA-Z]\)\(Twenty\)/\120/gi' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\([^a-zA-Z]\)0\?\([0-9]\)teen/\11\2/gi' '+1,$s/\([^a-zA-Z]\)\(Fifteen\)/\115/gi' '+1,$s/\([^a-zA-Z]\)\(Thirteen\)/\113/gi' '+1,$s/\([^a-zA-Z]\)\(Twelve\)/\112/gi' '+1,$s/\([^a-zA-Z]\)\(Eleven\)/\111/gi' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/^\v([0-9])([^0-9])/0\1\2/' '+1,$s/\v([^0-9])([0-9])([^0-9])/\10\2\3/g' '+1,$s/\v([^0-9])([0-9])$/\10\2/' '+wq!' './00-titles.lst';
	
	#start: fixing/renaming roman numerals
	ex -s '+1,$s/\ I\ /\ 1\ /g' '+1,$s/\ II\ /\ 2\ /g' '+1,$s/\ III\ /\ 3\ /g' '+1,$s/\ IV\ /\ 4\ /g' '+1,$s/\ V\ /\ 5\ /g' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\ VI\ /\ 6\ /g' '+1,$s/\ VII\ /\ 7\ /g' '+1,$s/\ VIII\ /\ 8\ /g' '+1,$s/\ IX\ /\ 9\ /g' '+1,$s/\ X\ /\ 10\ /g' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\ XI\ /\ 11\ /g' '+1,$s/\ XII\ /\ 12\ /g' '+1,$s/\ XIII\ /\ 13\ /g' '+1,$s/\ XIV\ /\ 14\ /g' '+1,$s/\ XV\ /\ 15\ /g' '+wq!' './00-titles.lst';
	ex -s '+1,$s/\ XVI\ /\ 16\ /g' '+1,$s/\ XVII\ /\ 17\ /g' '+1,$s/\ XVIII\ /\ 18\ /g' '+1,$s/\ XIX\ /\ 19\ /g' '+1,$s/\ XX\ /\ 20\ /g' '+wq!' './00-titles.lst';
	
	ex -s '+1,$s/\//\ \-\ /g' '+1,$s/[\ ]\{2,\}/\ /g' '+wq!' './00-titles.lst';
	if(! ${?silent} ) \
		printf "[done]\n";
	if( ${?logging} ) \
		printf "[done]\n" >> "${download_log}";
	
	# Grabs the release dates of the podcast and all episodes.
	if(! ${?silent} ) \
		printf "Finding release dates...please be patient, I may need several moments\t\t";
	if( ${?logging} ) \
		printf "Finding release dates${please_wait_phrase}\t\t" >> "${download_log}";
	/bin/cp './00-feed.xml' './00-pubDates.lst';
	
	# Concatinates all data into one single string:
	ex -s '+1,$s/.*<\(item\|entry\)[^>]*>.*<\(pubDate\|updated\)[^>]*>\(.*\)<\/\(pubDate\|updated\)>.*<.*enclosure[^>]*\(url\|href\)=["'\'']\([^"'\'']\+\)["'\''].*<\/\(item\|entry\)>$/\3/ig' '+1,$s/.*<\(item\|entry\)[^>]*>.*<.*enclosure[^>]*\(url\|href\)=["'\'']\([^"'\'']\+\)["'\''].*<\(pubDate\|updated\)[^>]*>\(.*\)<\/\(pubDate\|updated\)>.*<\/\(item\|entry\)>$/\5/ig' '+1,$s/.*<\(item\|entry\)[^>]*>.*<\(pubDate\|updated\)[^>]*>\([^<]*\)<\/\(pubDate\|updated\)>.*<\/\(item\|entry\)>[\n\r]*//ig' '+wq!' './00-pubDates.lst';
	
	if(! ${?silent} ) \
		printf "[done]\n";
	if( ${?logging} ) \
		printf "[done]\n" >> "${download_log}";
	
	# Grabs the enclosures from the feed.
	# This 1st method only grabs one enclosure per item/entry.
	if(! ${?silent} ) \
		printf "Finding enclosures . . . this may take a few moments\t\t\t\t";
	if( ${?logging} ) \
		printf "Finding enclosures . . . this may take a few moments\t\t\t\t" >> "${download_log}";
	/bin/cp './00-feed.xml' './00-enclosures-01.lst';
	
	ex -s '+1,$s/.*<\(item\|entry\)[^>]*>.*<.*enclosure[^>]*\(url\|href\)=["'\'']\([^"'\'']\+\)["'\''].*<\/\(item\|entry\)>$/\3/ig' '+1,$s/.*<\(item\|entry\)[^>]*>.*<\/\(item\|entry\)>[\n\r]*//ig' '+wq!' '00-enclosures-01.lst';
	ex -s '+set ff=unix' '+0r ./00-enclosures-01.lst' '+1,$s/^[\ \t\n]\+//g' '+1,$s/[\ \t\n]\+$//g' '+1,$s/?/\\?/g' '+w! ./00-enclosures-01.lst' '+q!';
	
	# This second method grabs all enclosures.
	/bin/cp './00-feed.xml' './00-enclosures-02.lst';
	
	# Concatinates all data into one single string:
	ex -s '+1,$s/[\n][\ \t]*//g' '+wq!' './00-enclosures-02.lst';
	
	/bin/grep --perl-regex -s '.*<.*enclosure[^>]*>.*' './00-enclosures-02.lst' | sed 's/.*url=["'\'']\([^"'\'']\+\)["'\''].*/\1/gi' | sed 's/.*<link[^>]\+href=["'\'']\([^"'\'']\+\)["'\''].*/\1/gi' | sed 's/^\(http:\/\/\).*\(http:\/\/.*$\)/\2/gi' | sed -r 's/\<[^\>]*\>[\r\n]+//ig' >! './00-enclosures-02.lst';
	ex -s '+1,$s/\v^[\ \t\n]+//g' '+1,$s/\v[\ \t\n]+$//g' '+1,$s/\v\?/\\\?/g' '+wq!' './00-enclosures-02.lst';
	
	set enclosure_count_01=`cat "./00-enclosures-01.lst"`;
	set enclosure_count_02=`cat "./00-enclosures-02.lst"`;
	if( ${#enclosure_count_01} >= ${#enclosure_count_02} ) then
		/bin/mv "./00-enclosures-01.lst" "./00-enclosures.lst";
		/bin/rm -f "./00-enclosures-02.lst";
	else
		/bin/mv "./00-enclosures-02.lst" "./00-enclosures.lst";
		/bin/rm -f "./00-enclosures-01.lst";
	endif
	if(! ${?silent} ) \
		printf "[done]\n";
	if( ${?logging} ) \
		printf "[done]\n" >> "${download_log}";
	
	if(! ${?silent} ) \
		printf "Beginning to download: %s\n" "${title}";
	if( ${?logging} ) \
		printf "Beginning to download: %s\n" "${title}" >> "${download_log}";
	set episodes=();
	set total_episodes="`cat './00-enclosures.lst'`";
	if( ${?start_with} ) then
		if( ${start_with} > 1 ) then
			set start_with="`printf '%s-1\n' '${start_with}'`";
			ex -s "+1,${start_with}d" '+wq!' './00-enclosures.lst';
			ex -s "+1,${start_with}d" '+wq!' './00-titles.lst';
			ex -s "+1,${start_with}d" '+wq!' './00-pubDates.lst';
		endif
	endif
	if( ${?download_limit} ) then
		if( ${download_limit} > 0 ) then
			set download_limit="`printf '%s+1\n' '${download_limit}' | bc`";
			ex -s "+${download_limit},"\$"d" '+wq!' './00-enclosures.lst';
			ex -s "+${download_limit},"\$"d" '+wq!' './00-titles.lst';
			ex -s "+${download_limit},"\$"d" '+wq!' './00-pubDates.lst';
		endif
	endif
	
	set episodes="`cat './00-enclosures.lst'`";
	if(! ${?silent} ) \
		printf "\n\tDownloading %s out of %s episodes of:\n\t\t'%s'\n\n" "${#episodes}" "${#total_episodes}" "${title}";
	if( ${?logging} ) \
		printf "\n\tDownloading %s out of %s episodes of:\n\t\t'%s'\n\n" "${#episodes}" "${#total_episodes}" "${title}" >> "${download_log}";
	
	@ episodes_downloaded=0;
	@ episodes_number=0;
	goto fetch_episodes;
#fetch_podcast:

continue_download:
	if( -e "${my_feed_xml}" ) \
		/bin/rm -f "${my_feed_xml}";
	set episodes="`cat './00-enclosures.lst'`";
	if(! ${?silent} ) \
		printf "\n\tFinishing downloading %s episodes of:\n\t\t'%s'\n\n" "${#episodes}" "${title}";
	if( ${?logging} ) \
		printf "\n\tFinishing downloading %s episodes of:\n\t\t'%s'\n\n" "${#episodes}" "${title}" >> "${download_log}";
	@ episodes_downloaded=0;
	@ episodes_number=0;
#continue_download:

fetch_episodes:
	if( ${?episodes_filename} ) then
		printf "Cancelled downloading %s\n" "${episodes_filename}";
		if( -e "${episodes_filename}" ) then
			rm "${episodes_filename}";
		endif
		unset episode episodes_filename;
		onintr finish_fetching;
		sleep 2;
	endif
	
	foreach episode ( "`cat './00-enclosures.lst'`" )
		ex -s '+1d' '+wq!' "./00-enclosures.lst";
		@ episodes_number++;
		if( ${episodes_number} > 1 ) then
			if(! ${?silent} ) \
				printf "\n\n";
			if( ${?logging} ) \
				printf "\n\n" >> "${download_log}";
		endif
		goto fetch_episode;
	end
	goto finish_fetching;
#goto fetch_episodes:

fetch_episode:
	onintr fetch_episodes;
	
	set episodes_file="`printf '%s' '${episode}' | sed -r 's/.*\/([^\/\?]+)\??.*"\$"/\1/'`";
	set episodes_extension=`printf '%s' "${episodes_file}" | sed -r 's/.*\.([^\.\?]+)\??.*$/\1/'`;
	
	set episodes_pubdate="`cat './00-pubDates.lst' | head -${episodes_number} | tail -1 | sed 's/\?//g'`";
	
	#set episodes_title="`cat './00-titles.lst' | head -${episodes_number} | tail -1 | sed 's/\?//g' | sed -r 's/(["\""'\''\ \<\>\(\)\&\|\!\?\*\+\-])/\\\1/g'`";
	set episodes_title="`cat './00-titles.lst' | head -${episodes_number} | tail -1 | sed 's/\?//g' | sed -r 's/([*])/\\\1/g' | sed -r 's/(['\!'])/\\\1/g'`";
	set episodes_title_escaped="`cat './00-titles.lst' | sed -r 's/(["\""])/"\""\\"\"""\""/g' | sed -r 's/([*])/\\\1/g' | sed -r 's/(['\!'])/\\\1/g'`";
	
	if( "${episodes_title}" == "" ) \
		set episodes_title="`printf "\""%s"\"" "\""${episodes_file}"\"" | sed -r 's/(.*)\/([^\/]+)\.([^.]+)"\$"/\1/'`";
	
	if( "${episodes_pubdate}" != "" ) then
		set episodes_filename="${episodes_title}, released on: ${episodes_pubdate}.${episodes_extension}";
	else
		set episodes_filename="${episodes_title}.${episodes_extension}";
	endif
	
	if(! ${?silent} ) \
		printf "\n\n\t\tDownloading episode: %s(episodes_number)\n\t\tTitle: %s (episodes_title)\n\t\tReleased on: %s (episodes_pubDate)\n\t\tFilename: %s (episodes_filename)\n\t\tRemote file: %s (episodes_file)\n\t\tURI: %s (episode)\n" ${episodes_number} "${episodes_title}" "${episodes_pubdate}" "${episodes_filename}" "${episodes_file}" "${episode}";
	if( ${?logging} ) \
		printf "\n\n\t\tDownloading episode: %s(episodes_number)\n\t\tTitle: %s (episodes_title)\n\t\tReleased on: %s (episodes_pubDate)\n\t\tFilename: %s (episodes_filename)\n\t\tRemote file: %s (episodes_file)\n\t\tURI: %s (episode)\n" ${episodes_number} "${episodes_title}" "${episodes_pubdate}" "${episodes_filename}" "${episodes_file}" "${episode}" >> "${download_log}";
	
	# Skipping existing files.
	if( ${?fetch_all} ) then
		${download_command_with_options} "./${episodes_filename}" "${episode}"
		unset episodes_filename;
		goto fetch_episodes;
	endif
	
	if( -e "./${episodes_filename}" ) then
		if(! ${?silent} ) \
			printf "\t\t\t[skipped existing file]";
		if( ${?logging} ) \
			printf "\t\t\t[skipping existing file]" >> "${download_log}";
		unset episodes_filename;
		goto fetch_episodes;
	endif
	
	switch ( "`basename '${episodes_file}'`" )
		case "theend.mp3":
		case "caughtup.mp3":
		case "caught_up_1.mp3":
			if(! ${?silent} ) \
				printf "\t\t\t[skipping podiobook.com notice]";
			if( ${?logging} ) \
				printf "\t\t\t[skipping podiobook.com notice]" >> "${download_log}";
			unset episodes_filename;
			goto fetch_episodes;
			breaksw;
	endsw
	
	if( "`printf "\""%s"\"" "\""${episodes_file}"\"" | sed -r 's/.*(commentary).*/\1/ig'`" != "${episodes_file}" ) then
		if(! ${?silent} ) \
			printf "\t\t\t[skipping commentary track]";
		if( ${?logging} ) \
			printf "\t\t\t[skipping commentary track]" >> "${download_log}";
		unset episodes_filename;
		goto fetch_episodes;
	endif
	
	#if(! ${?download_extras} ) then
	#	if( "`printf "\""%s"\"" "\""${episodes_title_escaped}"\"" | sed -r 's/.*(commentary).*/\1/ig'`" != "${episodes_title_escaped}" ) then
	#		if(! ${?silent} ) \
	#			printf "\t\t\t[skipping commentary track]";
	#		if( ${?logging} ) \
	#			printf "\t\t\t[skipping commentary track]" >> "${download_log}";
	#		unset episodes_filenames;
	#		goto fetch_episode;
	#	endif
	#endif
	
	if( ${?regex_match_titles} ) then
		if( "`printf '%s' "\""${episodes_title_escaped}"\"" | sed -r s/.*\(${regex_match_titles}\).*/\1/ig'`" )!="${episodes_title}" ) then
			printf "\t\t\t[skipping regexp matched episode]";
			unset episodes_filename;
			goto fetch_episodes;
		endif
	endif
	
	if( ${?list_episodes} ) then
		printf "%s <%s>\n" "${episodes_filename}" "${episode}";
		unset episodes_filename;
		goto fetch_episodes;
	endif
	
	if( ${?save_script} ) then
		printf 'Saving %s; episode: <%s> download to: <file://%s>\n' "${title}" "${episodes_title}" "${save_script}";
		printf '%s %s %s\n' "${download_command_with_options}" "./${episodes_filename}" "${episode}" >> "${save_script}";
		unset episodes_filename;
		goto fetch_episodes;
	endif
	
	if( ${?downloading} ) then
		${download_command_with_options} "./${episodes_filename}" "${episode}";
		
		if(! -e "./${episodes_filename}" ) then
			if(! ${?silent} ) \
				printf "\t\t\t[*epic fail* :(]";
			if( ${?logging} ) \
				printf "\t\t\t[*pout* :(]" >> "${download_log}";
		else
			@ episodes_downloaded++;
			if(! ${?silent} ) \
				printf "\t\t\t[*w00t\!*, FTW\!]";
			if( ${?logging} ) \
				printf "\t\t\t[*w00t\!*, FTW\!]" >> "${download_log}";
			if( ${?playlist} ) then
				printf "%s/%s\n" "${cwd}" "${episodes_filename}" >> "${playlist}";
			endif
		endif
	endif
	unset episodes_filename;
	goto fetch_episodes;
#goto fetch_episode;


finish_fetching:
	if(! ${?diagnostic_mode} ) then
		if( -e './00-titles.lst' ) \
			/bin/rm -f './00-titles.lst';
		if( -e './00-enclosures.lst' ) \
			/bin/rm -f './00-enclosures.lst';
		if( -e './00-pubDates.lst' ) \
			/bin/rm -f './00-pubDates.lst';
		if( -e './00-feed.xml' ) \
			/bin/rm -f './00-feed.xml';
	endif
	
	if(! ${?silent} ) \
		printf "\n\n*w00t\!*, I'm done; enjoy online media at its best!\n";
	if( ${?logging} ) \
		printf "\n\n*w00t\!*, I'm done; enjoy online media at its best!\n" >> "${download_log}";
	
	if( ${?playlist} ) then
		playlist:new:save.tcsh "${playlist}";
	endif
	
	if( ${?old_owd} ) then
		cd "${owd}";
		set owd="${old_owd}";
		unset old_owd;
	endif
	unset feed title episodes_filename;
	goto fetch_podcasts;
finish_fetching:

exit_script:
	if(! ${?diagnostic_mode} ) then
		if( -e './00-titles.lst' ) \
			/bin/rm -f './00-titles.lst';
		if( -e './00-enclosures.lst' ) \
			/bin/rm -f './00-enclosures.lst';
		if( -e './00-pubDates.lst' ) \
			/bin/rm -f './00-pubDates.lst';
		if( -e './00-feed.xml' ) \
			/bin/rm -f './00-feed.xml';
	endif
	
	if( -e "${alacasts_download_log}" ) \
		/bin/rm -f "${alacasts_download_log}";
	
	if( ${?starting_old_owd} ) then
		cd "${owd}";
		set owd="${starting_old_owd}";
		unset starting_old_owd;
	endif
	
	if( ${?oldcwdcmd} ) then
		alias cwdcmd $oldcwdcmd;
		unset oldcwdcmd;
	endif
	
	exit ${status};
#exit_script:

usage:
	printf "Usage: %s [ (--start-with)=1..10..? ] [ (--download-limit)=1..10..? ] [ --quiet ] XML_URI\n" `basename ${0}`;
	goto exit_script;
#usage:


parse_argv:
	set argc=${#argv};
	
	if( ${argc} == 0 ) \
		goto usage;
	
	@ arg=0;
	while( $arg < $argc )
		@ arg++;
		switch("$argv[$arg]")
			case "--diagnosis":
			case "--diagnostic-mode":
				printf "**%s debug:**, via "\$"argv[%d], diagnostic mode\t[enabled].\n\n" "${scripts_basename}" $arg;
				set diagnostic_mode;
				break;
			
			case "--debug":
				printf "**%s debug:**, via "\$"argv[%d], debug mode\t[enabled].\n\n" "${scripts_basename}" $arg;
				set debug;
				break;
			
			default:
				continue;
		endsw
	end
	
	@ arg=0;
	@ parsed_argc=0;
	
	if( ${?debug} ) \
		printf "Checking %s's argv options.  %d total.\n" "${scripts_basename}" "${argc}";
#parse_argv:

parse_arg:
	while ( $arg < $argc )
		if(! ${?arg_shifted} ) \
			@ arg++;
		
		if( ${?debug} || ${?diagnostic_mode} ) \
			printf "**%s debug:** Checking argv #%d (%s).\n" "${scripts_basename}" "${arg}" "$argv[$arg]";
		
		set dashes="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\1/'`";
		if( "${dashes}" == "$argv[$arg]" ) \
			set dashes="";
		
		set option="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\2/'`";
		if( "${option}" == "$argv[$arg]" ) \
			set option="";
		
		set equals="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\3/'`";
		if( "${equals}" == "$argv[$arg]" || "${equals}" == "" ) \
			set equals="";
		
		set equals="";
		set value="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\4/'`";
		if( "${value}" != "" && "${value}" != "$argv[$arg]" ) then
			set equals="=";
		else if( "${option}" != "" ) then
			@ arg++;
			if( ${arg} > ${argc} ) then
				@ arg--;
			else
				set test_dashes="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\1/'`";
				set test_option="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\2/'`";
				set test_equals="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\3/'`";
				set test_value="`printf "\""$argv[$arg]"\"" | sed -r 's/^([\-]{1,2})([^\=]+)(=?)['\''"\""]?(.*)['\''"\""]?"\$"/\4/'`";
				
				if( ${?debug} || ${?diagnostic_mode} ) \
					printf "\tparsed %sargv[%d] (%s) to test for replacement value.\n\tparsed %stest_dashes: [%s]; %stest_option: [%s]; %stest_equals: [%s]; %stest_value: [%s]\n" \$ "${arg}" "$argv[$arg]" \$ "${test_dashes}" \$ "${test_option}" \$ "${test_equals}" \$ "${test_value}";
				
				if(!("${test_dashes}" == "$argv[$arg]" && "${test_option}" == "$argv[$arg]" && "${test_equals}" == "$argv[$arg]" && "${test_value}" == "$argv[$arg]")) then
					@ arg--;
				else
					set equals="=";
					set value="$argv[$arg]";
					set arg_shifted;
				endif
				unset test_dashes test_option test_equals test_value;
			endif
		endif
		
		if( "`printf "\""${value}"\"" | sed -r "\""s/^(~)(.*)/\1/"\""`" == "~" ) then
			set value="`printf "\""${value}"\"" | sed -r "\""s/^(~)(.*)/${escaped_home_dir}\2/"\""`";
		endif
		
		if( "`printf "\""${value}"\"" | sed -r "\""s/^(\.)(.*)/\1/"\""`" == "." ) then
			set value="`printf "\""${value}"\"" | sed -r "\""s/^(\.)(.*)/${escaped_cwd}\2/"\""`";
		endif
		
		@ parsed_argc++;
		if(! ${?parsed_argv} ) then
			set parsed_argv="${dashes}${option}${equals}${value}";
		else
			set parsed_argv="${parsed_argv} ${dashes}${option}${equals}${value}";
		endif
		if( ${?debug} || ${?diagnostic_mode} ) \
			printf "\tparsed option %sparsed_argv[%d]: %s\n" \$ "$parsed_argc" "${dashes}${option}${equals}${value}";
		
		switch ( "${option}" )
			case "h":
			case "help":
				goto usage;
				breaksw;
			
			case "oldest":
			case "last":
			case "stop-with-episode":
			case "stop-with":
			case "stop-at-episode":
			case "stop-at":
			case "download-limit":
				if(!( "${value}" != "" && ${value} > 0 )) then
					printf "%s%s must be followed by a valid number greater than zero." "${dashes}" "${option}";
					breaksw;
				endif
				
				set download_limit="${value}";
				breaksw;
			
			case "newest":
			case "first":
			case "start-with-episode":
			case "start-with":
			case "start-at-episode":
			case "start-at":
				if(! ( "${value}" != "" && ${value} > 0 )) then
					printf "%s%s must be followed by a valid number greater than zero." "${dashes}" "${option}";
					breaksw;
				endif
				
				set start_with=${value};
				breaksw;
			
			case "o":
			case "O":
			case "output":
			case "output-document":
			case "script":
			case "save-as":
			case "save-script":
				if( "${value}" != "" && -d "`dirname '${value}'`" ) then
					set save_script="${value}";
					printf "Enclosures will not be downloaded but instead the script: <file://%s> will be created.\n" "${save_script}";
					breaksw;
				endif
				
				@ arg++;
				if( $arg > $argc ) then
					@ arg--;
					printf "%s%s script's target must be within existing directory.  The script cannot be saved.\n" "${dashes}" "${option}" > /dev/stderr;
					goto exit_script;
				endif
				
				if(!( "$argv[$arg]" != "" && -d "`dirname '$argv[$arg]'`" )) then
					printf "%s%s script's target must be within existing directory.  The script cannot be saved.\n" "${dashes}" "${option}" > /dev/stderr;
					goto exit_script;
				endif
				
				set save_script="$argv[$arg]";
				printf "Enclosures will not be downloaded but instead the script: <file://%s> will be created.\n" "${save_script}";
				
				breaksw;
			
			case "l":
			case "ls":
			case "list":
			case "list-episodes":
				set list_episodes;
				breaksw;
			
			case "s":
			case "q":
			case "silent":
			case "quiet":
				set silent;
				breaksw;
			
			case "f":
			case "force":
			case "force-fetch":
			case "force-all":
				set fetch_all;
				breaksw;
			
			case "save-to":
			case "download-to":
			case "download-dir":
			case "download-directory":
				if( "${value}" == "" ) then
					@ arg++;
					if( $arg > $argc ) then
						@ arg--;
					else
						set value="$argv[$arg]";
					endif
				endif
				if(!( "${value}" != "" && -d "${value}" )) then
					printf "%s%s must specify a valid and existing target directory.  See %s -h|--help for more information.\n" "${dashes}" "${option}" "${scripts_basename}";
				else
					set save_to_dir="${value}";
				endif
				breaksw;
			
			case "regex-match-titles":
				if( "${value}" == "" ) \
					breaksw;
				set regex_match_titles="${value}";
				breaksw;
			
			case "logging":
				if(! ${?logging} ) \
					set logging;
				breaksw;
			
			case "debug":
				if(! ${?debug} ) \
					set debug;
				breaksw;
			
			case "diagnosis":
			case "diagnostic-mode":
				if(! ${?diagnostic_mode} ) \
					set diagnostic_mode;
				breaksw;
			
			case "download-all":
			case "download-extras":
				if(! ${?download_extras} ) \
					set download_extras;
				breaksw;
			
			case "playlist":
				set playlist;
				switch("${value}")
					case "pls":
					case "tox":
					case "m3u":
						set playlist_type="${value}";
						breaksw;
					
					default:
						set playlist_type="m3u";
						breaksw;
				endsw
				breaksw;
			
			case "enable":
				switch( ${value} )
					case "logging":
						if( ${?logging} ) \
							breaksw;
						
						set logging;
						breaksw;
					
					case "extras":
					case "download-extras":
						if(! ${?download_extras} ) \
							set download_extras;
						breaksw;
					
					case "downloading":
						if( ${?downloading} ) \
							breaksw;
						
						set downloading;
						breaksw;
					
					case "verbose":
						if(! ${?be_verbose} ) \
							breaksw;
						
						printf "**%s debug:**, via "\$"argv[%d], verbose output\t[enabled].\n\n" "${scripts_basename}" $arg;
						set be_verbose;
						breaksw;
					
					case "debug":
						if( ${?debug} ) \
							breaksw;
						
						printf "**%s debug:**, via "\$"argv[%d], debug mode\t[enabled].\n\n" "${scripts_basename}" $arg;
						set debug;
						breaksw;
					
					case "diagnosis":
					case "diagnostic-mode":
						if( ${?diagnostic_mode} ) \
							breaksw;
						
				
						printf "**%s debug:**, via "\$"argv[%d], diagnostic mode\t[enabled].\n\n" "${scripts_basename}" $arg;
						set diagnostic_mode;
						breaksw;
					
					default:
						printf "enabling %s is not supported by %s.  See %s --help\n" "${value}" "${scripts_basename}" "${scripts_basename}";
						breaksw;
				endsw
				breaksw;
			
			case "disable":
				switch( ${value} )
					case "logging":
						if(! ${?logging} ) \
							breaksw;
						
						unset logging;
						breaksw;
					
					case "extras":
					case "download-extras":
						if( ${?download_extras} ) \
							unset download_extras;
						breaksw;
					
					case "downloading":
						if(! ${?downloading} ) \
							breaksw;
						
						unset downloading;
						breaksw;
					
					case "verbose":
						if(! ${?be_verbose} ) \
							breaksw;
						
						printf "**%s debug:**, via "\$"argv[%d], verbose output\t[disabled].\n\n" "${scripts_basename}" $arg;
						unset be_verbose;
						breaksw;
					
					case "debug":
						if(! ${?debug} ) \
							breaksw;
						
						printf "**%s debug:**, via "\$"argv[%d], debug mode\t[disabled].\n\n" "${scripts_basename}" $arg;
						unset debug;
						breaksw;
					
					case "diagnosis":
					case "diagnostic-mode":
						if(! ${?diagnostic_mode} ) \
							breaksw;
						
						printf "**%s debug:**, via "\$"argv[%d], diagnostic mode\t[disabled].\n\n" "${scripts_basename}" $arg;
						unset diagnostic_mode;
						breaksw;
					
					default:
						printf "disabling %s is not supported by %s.  See %s --help\n" "${value}" "${scripts_basename}" "${scripts_basename}";
						breaksw;
				endsw
				breaksw;
			case "htmlUrl":
			case "title":
			case "text":
			case "description":
				breaksw;
			
			case "xmlUrl":
			default:
				if( "${option}" != "" && "${option}" != "xmlUrl" ) then
					printf "%s%s is an unsupported option.  See %s -h|--help for more information.\n" "${dashes}" "${option}" "${scripts_basename}";
					goto exit_script;
				endif
				if( "${value}" == "" ) \
					set value="$argv[$arg]";
				if( "`echo '${value}' | sed -r 's/^(http|https|ftp)(:\/\/).*/\2/i'`" != "://" ) then
					if( "${option}" != "" ) then
						printf "%s%s=[url] must specify a valid http, https, or ftp URI.\n" "${dashes}" "${option}" > /dev/stderr;
					else
						printf "A valid http, https, or ftp feeds URI must be specified.\n";
					endif
				else
					printf "%s\n" "${value}" >> "${alacasts_download_log}";
				endif
				breaksw;
		endsw
		
		if( ${?arg_shifted} ) then
			unset arg_shifted;
			@ arg--;
		endif
		
		unset dashes option equals value;
	end
	goto main;
#parse_argv:

