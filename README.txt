These are Backup and Restore Scripts designed for use on Windows XP,Vista, and 7.
I originally developed these to simplify backups for my family. 

At that point, I had a few goals:
1)Backup everything that might be of value (i.e. the whole user profile)
2)The Backup must simply be a copy of the directories and files, to simplify
	restore, especially of partial files.
3)Quick. Only copy files that had changed between runs. We have 100's of GBs of
	data and it shouldn't be copied every time we backup.
4)Simple. Something that my mother would be able to run (and would run)

At the top of both scripts, you will notice an area called "Configuration". You
may want to modify these variables to suit your needs, though they are likely
general enough for most use.

The Backup script, in particular, includes options to backup a specific Thunderbird
profile to an additional spot. If you use Thunderbird for your email, you may
consider using that. There is also an option to double backup pictures. Both of
these options are disabled by default.

I have tried to keep the dependencies of these scripts as minimal as possible.
However, due to the total lack of useful utilities on Windows, there are a few
dependencies:
1)Robocopy. Should be included by default on pretty much all Windows systems. 
	If not,	you can download it by following the links from: 
	http://edi.idglabs.net/?p=2737

2)Vscsc--The Volume Shadow Copy Simple Client. A free, open-source program
	available on SourceForge: http://sourceforge.net/projects/vscsc/.
	The current version as of this writing is included in this repo for
	simplicity.

3)dosdev. Another free, open-source program. I have not been able to find the
	original source of this program; however, it is mirrored on the VSCSC
	sourceforge site: http://sourceforge.net/projects/vscsc/files/utilities/.
	The current version as of this writing is included in this repo for
	simplicity.

These utlities need to be present in your PATH. This can usually be done by placing
them in C:\Windows or C:\Windows\system32.

These scripts are free software: you can redistribute them and/or modify
them under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

These scripts are distributed in the hope that they will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with these scripts.  If not, see <http://www.gnu.org/licenses/>.

Samuel Jero
Doctoral Student
Computer Science
Dependable and Secure Distributed Systems Lab
Purdue University
sjero@purdue.edu

12-26-2013
