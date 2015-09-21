module DeployData

	require 'pp'
	require 'yaml'

	REXHOST = 'sjopstools'
	#REXHOST = 'sjreleng1'

	class DeployDB

		attr_accessor :dbdatacenters
		attr_accessor :dbpods
		attr_accessor :dbpodservers

		def initialize
			@dbdatacenters = Hash.new
			@dbpods = Hash.new
			@dbpodservers = Hash.new

			@dclist = ['ab', 'lon', 'sj', 'sn']

			@dclist.each do |dc|
				@dbdatacenters["#{dc}"] = DeployDatacenter.new(self, dc)
			end
		end

		def get_dclist
			return @dclist
		end

		def get_podlist(dcname, app)
			podhash = self.dbdatacenters["#{dcname}"].dcpods

			podlist = Array.new
			podhash.each do |k,v|
				if v.podapp == app
					podlist.push(v.podname)
				end
			end
			return podlist
		end

		def find_pod(podname)
			thispod = nil
			self.dbpods.each do |k,v|
				if "#{k}" == "#{podname}"
					thispod = v
					break
				end
			end
			return thispod
		end

		def get_serverlist(podname, servertype, needs_primary=false)
			pod = self.dbpods["#{podname}"]
			serverhash = pod.podservers
			serverlist = Array.new
			serverhash.each do |k,v|
				if servertype == 'all'
					serverlist.push(v.podservername)
				elsif v.podservertype == servertype
					if needs_primary
						if v.is_primary
							serverlist.push(v.podservername)
						end
					else
						serverlist.push(v.podservername)
					end
				end
			end
			return serverlist
		end
	end

	class DeployDatacenter

		attr_accessor :dcname
		attr_accessor :dcpods

		def initialize(db, dcname)
			@dcname = dcname
			@dcpods = Hash.new

			case dcname

			when 'ab'

				app = 'MLM'
				mlm_podnames = ['ab01', 'ab02', 'ab03', 'ab04', 'ab05', 'ab06', 'ab07', 'ab08', 'ab09', 'ab10',
												'ab11', 'ab12', 'ab13', 'aba', 'abb', 'abc', 'abd', 'abj', 'abk', 'abm', 'abq']
				mlm_podnames.each do |p|
					thispod = DeployPod.new(db, dcname, p, app)
					@dcpods["#{p}"] = thispod

					this_servertype = 'web'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'be'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2', '3', '4', '5', '6']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

				end

				app = 'RCA'
				rca_podnames = ['rca01', 'rca02', 'rca03', 'rca04', 'rca05', 'rca06']
				rca_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'etl'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					is_primary = false
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						if "#{i}" == '1'
							is_primary - true
						end
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype, is_primary)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'fe'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Sandbox'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'EmailRpt'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Dynamics'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'TrackingServer'
				sandbox_podnames = ['track0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2', '3', '4']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktUrl'
				sandbox_podnames = ['shorturl']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktMail'
				sandbox_podnames = ['mas0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'JlogReader'
				sandbox_podnames = ['mta']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

			when 'lon'
				app = 'MLM'
				mlm_podnames = ['e', 'lon02', 'lon03', 'lon04']
				mlm_podnames.each do |p|
					thispod = DeployPod.new(db, dcname, p, app)
					@dcpods["#{p}"] = thispod

					this_servertype = 'web'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'be'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2', '3', '4', '5', '6']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'RCA'
				rca_podnames = ['rca01', 'rca02']
				rca_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'etl'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					is_primary = false
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						if "#{i}" == '1'
							is_primary - true
						end
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype, is_primary)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'fe'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Sandbox'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'EmailRpt'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Dynamics'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'TrackingServer'
				sandbox_podnames = ['track0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktUrl'
				sandbox_podnames = ['mas']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktMail'
				sandbox_podnames = ['mas']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'JlogReader'
				sandbox_podnames = ['mta']
				sandbox_podnames.each do |p|
					podname = "#{dcname}-#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

			when 'sj'

				app = 'MLM'
				mlm_podnames = ['cs', 'sj01', 'sj02', 'sj03', 'sj04', 'sj05', 'sj06', 'sj07', 'sj08', 'sj09', 'sj10',
												'sj11', 'sj12', 'sj13', 'abf', 'abg', 'abh', 'abi', 'abl', 'abn', 'abo', 'abp']
				mlm_podnames.each do |p|
					thispod = DeployPod.new(db, dcname, p, app)
					@dcpods["#{p}"] = thispod

					this_servertype = 'web'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'be'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2', '3', '4', '5', '6']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server

						# Pods cs and sj06 are "mini-pods"
						if "#{p}" == 'cs' or "#{p}" == 'sj06'
							if "#{i}" == '4'
								break
							end
						end
					end
				end

				app = 'RCA'
				rca_podnames = ['rca01', 'rca02', 'rca03', 'rca04', 'rca05', 'rca06', 'rca07', 'rca08']
				rca_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'etl'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					is_primary = false
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						if "#{i}" == '1'
							is_primary - true
						end
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype, is_primary)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'fe'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Sandbox'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'EmailRpt'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Dynamics'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'TrackingServer'
				sandbox_podnames = ['track0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktUrl'
				sandbox_podnames = ['shorturl']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktMail'
				sandbox_podnames = ['mas0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'JlogReader'
				sandbox_podnames = ['mta']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

			when 'sn'

				app = 'MLM'
				mlm_podnames = ['sn01']
				mlm_podnames.each do |p|
					thispod = DeployPod.new(db, dcname, p, app)
					@dcpods["#{p}"] = thispod

					this_servertype = 'web'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'be'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2', '3', '4', '5', '6']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, p, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'RCA'
				rca_podnames = ['rca01']
				rca_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'etl'
					this_serverroot = "#{p}#{this_servertype}"

					servicegroup = ['1', '2']
					is_primary = false
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						if "#{i}" == '1'
							is_primary - true
						end
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype, is_primary)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end

					this_servertype = 'fe'
					this_serverroot = "#{p}#{this_servertype}"
							
					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Sandbox'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'EmailRpt'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'Dynamics'
				sandbox_podnames = ['smx']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'TrackingServer'
				sandbox_podnames = ['track0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktUrl'
				sandbox_podnames = ['shorturl']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'MktMail'
				sandbox_podnames = ['mas0']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['1', '2']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end

				app = 'JlogReader'
				sandbox_podnames = ['mta']
				sandbox_podnames.each do |p|
					podname = "#{dcname}#{p}"
					thispod = DeployPod.new(db, dcname, podname, app)
					@dcpods["#{podname}"] = thispod

					this_servertype = 'app' # Doesn't affect the root name
					this_serverroot = "#{p}"

					servicegroup = ['01', '02']
					servicegroup.each do |i|
						this_servername = "#{this_serverroot}#{i}"
						serverindex = "#{i}"
						this_server = DeployPodserver.new(db, dcname, podname, app, this_servername, this_servertype)
						db.dbpodservers["#{this_servername}"] = this_server
						thispod.podservers["#{this_servername}"] = this_server
					end
				end
			end
		end
	end

	class DeployPod

		attr_accessor :dcname
		attr_accessor :podname
		attr_accessor :podapp
		attr_accessor :podservers

		def initialize(db, dcname, podname, app)
			@dcname = dcname
			@podname = podname
			@podapp = app
			@podservers = Hash.new
			db.dbpods["#{podname}"] = self
		end
	end

	class DeployPodserver

		attr_accessor :datacenter
		attr_accessor :podname
		attr_accessor :podapp
		attr_accessor :podservername			
		attr_accessor :podservertype
		attr_accessor :is_primary

		def initialize(db, dcname, podname, podapp, podservername, podservertype, is_primary=false)
			@datacenter = dcname
			@podname = podname
			@podapp = podapp
			@podservername = podservername
			@podservertype = podservertype
			@is_primary = is_primary
		end
	end
end
