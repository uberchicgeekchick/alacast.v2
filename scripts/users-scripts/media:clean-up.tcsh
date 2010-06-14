#!/bin/tcsh -f

parse_argv:
	if(! ${?arg} ) then
		@ arg=0;
		@ argc=${#argv};
		if( $argc == 0 ) \
			goto clean_up;
	else if ${?callback} then
		goto ${callback};
	endif
	
	while( $arg < $argc )
		@ arg++;
		switch( "$argv[${arg}]" )
			case "--clean-up":
				goto clean_up;
				breaksw;
				
			case "--playlists":
				goto playlists;
				breaksw;
				
			case "--move":
				goto move;
				breaksw;
				
			case "--back-up":
				goto back_up;
				breaksw;
				
			case "--delete":
				goto delete;
				breaksw;
				
			case "--logs":
				goto logs;
				breaksw;
				
			case "--clean-playlists":
				goto alacasts_playlists;
				breaksw;
				
			case "--validate-playlists":
				goto validate_playlists;
				breaksw;
				
			default:
				goto clean_up;
				breaksw;
				
		endsw
	end
	goto exit_script;
#goto parse_argv;


exit_script:
	if( ${?action_preformed} ) \
		unset action_preformed;
	exit 0;
#goto exit_script;


clean_up:
	set callback="clean_up";
	if(! ${?goto_index} ) then
		@ goto_index=0;
		printf "\tWould you like to validate existing playlists? [Yes/No(default)]" > /dev/stdout;
		set confirmation="$<";
		#set rconfirmation=$<:q;
		printf "\n";
		
		switch(`printf "%s" "${confirmation}" | sed -r 's/^(.).*$/\l\1/'`)
			case "y":
				unset confirmation;
				set validate_playlists;
				breaksw;
			
			case "n":
			default:
				unset confirmation;
			breaksw;
		endsw
	else
		@ goto_index++;
		if( ${?action_preformed} ) then
			printf "\n\n";
			unset action_preformed;
		endif
	endif
	
	switch( $goto_index )
		case 0:
			goto move_podiobooks;
			breaksw;
		
		case 1:
			goto move_slashdot;
			breaksw;
		
		case 2:
			goto delete;
			breaksw;
		
		case 3:
			goto back_up;
			breaksw;
		
		case 4:
			goto alacasts_playlists;
			breaksw;
		
		case 5:
			goto logs;
			breaksw;
		
		case 6:
			if( ${?validate_playlists} ) \
				goto validate_playlists;
			
		default:
			unset goto_index callback;
			breaksw;
	endsw
	goto parse_argv;
#goto clean_up;


playlists:
	set callback="playlists";
	if(! ${?goto_index} ) then
		@ goto_index=0;
	else
		@ goto_index++;
		if( ${?action_preformed} ) then
			printf "\n\n";
			unset action_preformed;
		endif
	endif
	
	switch( $goto_index )
		case 0:
			goto alacasts_playlists;
			breaksw;
		
		case 1:
			goto validate_playlists;
			breaksw;
		
		case 2:
			goto logs;
			breaksw;
		
		default:
			unset goto_index callback;
			breaksw;
	endsw
	goto parse_argv;
#goto playlists;


move_podiobooks:
	set podiobooks=( \
	"\n" \
	);
	
	if( ${?podiobooks} ) then
		foreach podiobook( "`printf "\""${podiobooks}"\"" | sed -r 's/^\ //' | sed -r 's/\ "\$"//'`" )
			if( "${podiobook}" != "" && "${podiobook}" != "/" && -e "${podiobook}" ) then
				if(! ${?action_preformed} ) then
					set action_preformed;
				else if( ${?action_preformed} ) then
					printf "\n\n";
				endif
				
				if(! -d "/media/podiobooks/Latest" ) \
					mkdir -p  "/media/podiobooks/Latest";
				
				if(! -d "${podiobook}" ) then
					set podiobook="`dirname "\""${podiobook}"\""`";
				endif
				
				if(! -d "/media/podiobooks/Latest/`basename "\""${podiobook}"\""`" ) then
					mv -vi \
						"${podiobook}" \
					"/media/podiobooks/Latest";
				else
					mv -vi \
						"${podiobook}/"* \
					"/media/podiobooks/Latest/`basename "\""${podiobook}"\""`";
					if( `/bin/ls -A "${podiobook}"` == "" ) \
						rmdir -v "${podiobook}";
				endif
			endif
			unset podiobook;
		end
		unset podiobooks;
	endif
	
	goto parse_argv;
#goto move_podiobooks;


move_slashdot:
	set slashdot=( \
	"\n" \
	);
	
	if( ${?slashdot} ) then
		foreach podcast( "`printf "\""${slashdot}"\"" | sed -r 's/^\ //' | sed -r 's/\ "\$"//'`" )
			if( "${podcast}" != "" && "${podcast}" != "/" && -e "${podcast}" ) then
				if(! ${?action_preformed} ) then
					set action_preformed;
				else if( ${?action_preformed} ) then
					printf "\n\n";
				endif
				
				if(! -d "/media/podcasts/slash." ) \
					mkdir -p  "/media/podcasts/slash.";
				
				mv -vi \
					"${podcast}" \
				"/media/podcasts/slash.";
				
				set podcast_dir="`dirname "\""${podcast}"\""`";
				if( `/bin/ls -A "${podcast_dir}"` == "" ) \
					rmdir -v "${podcast_dir}";
				unset podcast_dir;
			endif
			unset podcast;
		end
		unset slashdot;
	endif
	
	goto parse_argv;
#goto move_slashdot;


delete:
	set to_be_deleted=( \
	"\n" \
	);
	
	if( ${?to_be_deleted} ) then
		foreach podcast( "`printf "\""${to_be_deleted}"\"" | sed -r 's/^\ //' | sed -r 's/\ "\$"//'`" )
			if( "${podcast}" != "" && "${podcast}" != "/" && -e "${podcast}" ) then
				if(! ${?action_preformed} ) then
					set action_preformed;
				else if( ${?action_preformed} ) then
					printf "\n\n";
				endif
				
				if( -d "${podcast}" ) then
					rm -rv "${podcast}";
					continue;
				endif
				
				rm -v "${podcast}";
				
				set podcast_dir="`dirname "\""${podcast}"\""`";
				if( `/bin/ls -A "${podcast_dir}"` == "" ) \
					rmdir -v "${podcast_dir}";
				unset podcast_dir;
			endif
			unset podcast;
		end
		unset to_be_deleted;
	endif
	
	set directories_to_delete=( \
	"\n" \
	);
	
	if( ${?directories_to_delete} ) then
		foreach podcast( "`printf "\""${directories_to_delete}"\"" | sed -r 's/^\ //' | sed -r 's/\ "\$"//'`" )
			if( "${podcast}" != "" && "${podcast}" != "/" && -e "${podcast}" ) then
				set podcast_dir="`dirname "\""${podcast}"\""`";
				if( "${podcast_dir}" != "/media/podcasts" && -d "${podcast_dir}" ) then
					if(! ${?action_preformed} ) then
						set action_preformed;
					else if( ${?action_preformed} ) then
						printf "\n\n";
					endif
					
					rm -rv \
						"${podcast_dir}";
				endif
			endif
			unset podcast_dir podcast;
		end
		unset directories_to_delete;
	endif
	
	if( -d "/media/podcasts/Slashdot" ) then
		if(! ${?action_preformed} ) then
			set action_preformed;
		else if( ${?action_preformed} ) then
			printf "\n\n";
		endif
		
		rm -rv "/media/podcasts/Slashdot";
	endif
	
	goto parse_argv;
#goto delete;


back_up:
	set slashdot=( \
	"\n" \
	);
	
	if( ${?slashdot} ) then
		foreach podcast( "`printf "\""${slashdot}"\"" | sed -r 's/^\ //' | sed -r 's/\ "\$"//'`" )
			if( "${podcast}" != "" && "${podcast}" != "/" && -e "${podcast}" ) then
				if(! ${?action_preformed} ) then
					set action_preformed;
				else if( ${?action_preformed} ) then
					printf "\n\n";
				endif
				
				if(! -d "/art/media/resources/stories/Slashdot" ) \
					mkdir -p  "/art/media/resources/stories/Slashdot";
				
				mv -vi \
					"${podcast}" \
				"/art/media/resources/stories/Slashdot";
			endif
			if( `/bin/ls -A "/media/podcasts/slash."` == "" ) \
				rmdir -v "/media/podcasts/slash.";
			unset podcast;
		end
		unset slashdot;
	endif
	
	goto parse_argv;
#goto back_up;


alacasts_playlists:
	set playlist_dir="/media/podcasts/playlists/m3u";
	foreach playlist("`/bin/ls --width=1 -t "\""${playlist_dir}"\""`")
		set playlist_escaped="`printf "\""%s"\"" "\""${playlist}"\"" | sed -r 's/([\/.])/\\\1/g'`";
		if(! ${?playlist_count} ) then
			@ playlist_count=1;
		else
			@ playlist_count++;
		endif
		
		if( "`find "\""${playlist_dir}"\"" -iregex "\"".*\/\.${playlist_escaped}\.sw."\""`" != "" ) then
			printf "<file://%s/%s> is in use and will not be deleted.\n" "${playlist_dir}" "${playlist}" > /dev/stderr;
		else if( "`wc -l "\""${playlist_dir}/${playlist}"\"" | sed -r 's/^([0-9]+).*"\$"/\1/'`" > 1 ) then
			printf "<file://%s/%s> still lists files.\n\tWould you like to remove it:\n" "${playlist_dir}" "${playlist}" > /dev/stderr;
			rm -vi "${playlist_dir}/${playlist}";
			if(! -e "${playlist_dir}/${playlist}" ) then
				if(! ${?action_preformed} ) then
					set action_preformed;
				else if( ${?action_preformed} ) then
					printf "\n\n";
				endif
			endif
		else	
			if(! ${?action_preformed} ) then
				set action_preformed;
			else if( ${?action_preformed} ) then
				printf "\n\n";
			endif
			
			rm -v "${playlist_dir}/${playlist}";
		endif
		unset playlist_escaped playlist;
	end
	unset playlist_count playlist_dir;
	goto parse_argv;
#goto alacasts_playlists;


logs:
	set current_day=`date "+%d"`
	set current_month=`date "+%m"`
	set current_year=`date "+%Y"`;
	
	set current_hour=`date "+%k"`
	set current_hour=`printf "%d-(%d%%6)\n" "${current_hour}" "${current_hour}" | bc`;
	if( ${current_hour} < 10 ) \
		set current_hour="0${current_hour}";
	
	if( "`find /media/podcasts/ -regextype posix-extended -iregex '.*alacast'\''s log for .*' \! -iregex '.*alacast'\''s log for ${current_year}-${current_month}-${current_day} from ${current_hour}.*'`" != "" ) then
		if(! ${?action_preformed} ) then
			set action_preformed;
		else if( ${?action_preformed} ) then
			printf "\n\n";
		endif
		
		( rm -v "`find /media/podcasts/ -regextype posix-extended -iregex '.*alacast'\''s log for .*' \! -iregex '.*alacast'\''s log for ${current_year}-${current_month}-${current_day} from ${current_hour}.*'`" > /dev/tty ) >& /dev/null;
	endif
	
	goto parse_argv;
#goto logs;


validate_playlists:
	set playlist_data=( "/media/library/playlists/m3u/local.podcasts.m3u" "/media/podcasts" "/media/library/playlists/m3u/local.podiobooks.m3u" "/media/podiobooks/Latest" "/media/library/playlists/m3u/local.podiobooks.m3u" "/media/podiobooks/erotica/Literotica" "/media/library/playlists/m3u/eee.podcasts.m3u" "/media/podcasts" );
	@ playlist_index=0;
	while( $playlist_index < ${#playlist_data} )
		@ playlist_index++;
		set playlist=$playlist_data[$playlist_index];
		@ playlist_index++;
		set playlist_dir=$playlist_data[$playlist_index];
		@ playlist_check=-1;
		while( $playlist_check < 1 )
			@ playlist_check++;
			switch( $playlist_check )
				case 0:
					printf "\tWould you like to make sure that all files found under <file://%s> are listed in <file://%s>? [Yes/No(default)]" "${playlist_dir}" "${playlist}" > /dev/stdout;
					breaksw;
				
				case 1:
					printf "\tWould you like to make sure that all files in <file://%s> exist? [Yes/No(default)]" "${playlist}" > /dev/stdout;
					breaksw;
			endsw
			
			set confirmation="$<";
			#set rconfirmation=$<:q;
			printf "\n";
			
			switch(`printf "%s" "${confirmation}" | sed -r 's/^(.).*$/\l\1/'`)
				case "y":
					switch( $playlist_check )
						case 0:
							if("`playlist:find:missing:listings.tcsh ${playlist} ${playlist_dir} --extensions='(mp3|ogg|m4a|wma)' --remove=interactive`" != "" ) \
								printf "\n\n";
							breaksw;
						
						case 1:
							if("`playlist:find:non-existent:listings.tcsh --clean-up /media/library/playlists/m3u/local.podcasts.m3u`" != "" ) \
								printf "\n\n";
							breaksw;
					endsw
					breaksw;
				
				case "n":
				default:
					breaksw;
			endsw
			unset confirmation;
		end
		unset playlist_check playlist_dir playlist;
	end
	unset playlist_data playlist_index;
	
	goto parse_argv;
#goto validate_playlists;
