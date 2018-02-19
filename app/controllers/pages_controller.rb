class PagesController < ApplicationController
	def contact
	end

	def about
	end

	def humanize secs
		base = [[60, :seconds], [60, :minutes], [424242, :hours]].map{|count, name|
			if secs > 0
				secs, modulo = secs.divmod(count)
				"#{modulo.to_i} #{name}"
			else
				"#{0.to_i} #{name}"
			end
		}
		return base.compact.reverse.join(' ')
	end

	def parse_trimestre logtimes
		@trimestre = Hash.new
		trim_base = ["Jan-Feb-Mar", "Apr-May-Jun", "Jul-Aug-Sep", "Oct-Nov-Dec"]
		tmp = 0

		# logtimes.each do |val|
		# 	val['begin_at'] = Time.parse(val['begin_at'])
		# 	if val['end_at'] == nil
		# 		val['end_at'] = Time.now
		# 	else
		# 		val['end_at'] = Time.parse(val['end_at'])
		# 	end
		# end

		logtimes = logtimes.reverse

		first_log = logtimes.first['begin_at']
		last_log = logtimes.last['begin_at']
		i_trimestre = (first_log.month - 1) / 3
		i_year = first_log.year

		while (i_year <= last_log.year) do
			while (i_year < last_log.year && i_trimestre < 4) || (i_year == last_log.year && i_trimestre <= ((last_log.month - 1) / 3)) do
				key = trim_base[i_trimestre] + " " + i_year.to_s
				@trimestre[key] = 0
				i_trimestre += 1
			end
			i_trimestre = 0
			i_year += 1
		end



		logtimes.each do |val|
			key = trim_base[(val['begin_at'].month - 1) / 3] + " " + val['begin_at'].year.to_s
			if @trimestre[key] == nil
				@trimestre[key] = 0
			end
			@trimestre[key] += (val['end_at'] - val['begin_at']).to_i
		end

		@trimestre.each do |key, v_hash|
			@trimestre[key] = humanize v_hash
		end
	end


	def parse_allinone logtimes
		@allinone = Hash.new
		month_base = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		tmp = 0

		logtimes.each do |val|
			val['begin_at'] = Time.parse(val['begin_at'])
			if val['end_at'] == nil
				val['end_at'] = Time.now
			else
				val['end_at'] = Time.parse(val['end_at'])
			end
		end

		logtimes = logtimes.reverse

		first_log = logtimes.first['begin_at']
		last_log = logtimes.last['begin_at']
		i_month = first_log.month
		i_year = first_log.year

		while (i_year <= last_log.year) do
			while (i_year < last_log.year && i_month <= 12) || (i_year == last_log.year && i_month <= last_log.month) do
				key = month_base[i_month - 1] + " " + i_year.to_s
				@allinone[key] = 0
				i_month += 1
			end
			i_month = 1
			i_year += 1
		end

		logtimes.each do |val|
			key = month_base[val['begin_at'].month - 1] + " " + val['begin_at'].year.to_s
			if @allinone[key] == nil
				@allinone[key] = 0
			end
			@allinone[key] += (val['end_at'] - val['begin_at']).to_i
		end

		@allinone.each do |key, v_hash|
			@allinone[key] = humanize v_hash
		end
	end


	def parse_yearbyyear logtimes
		@yearbyyear = Hash.new
		month_base = {"Jan" => 0, "Feb" => 0, "Mar" => 0, "Apr" => 0, "May" => 0, "Jun" => 0, "Jul" => 0, "Aug" => 0, "Sep" => 0, "Oct" => 0, "Nov" => 0, "Dec" => 0}
		month_empty = month_base.clone
		tmp = 0

		logtimes = logtimes.reverse

		logtimes.push(0)
		logtimes.each do |val|
			if val != 0
				dbt = Time.parse(val['begin_at'])
				if val['end_at'] == nil
					fin = Time.now
				else
					fin = Time.parse(val['end_at'])
				end
			end
			if val == 0 || (tmp != 0 and dbt and tmp != dbt.year)
				@yearbyyear[tmp] = month_empty
				month_empty = month_base.clone
			end
			if val != 0
				tmp = dbt.year
				month_empty[month_empty.keys[dbt.month - 1]] += (fin - dbt).to_i # sum this val in the month_empty array
			end
		end
		logtimes.pop

		@yearbyyear.each do |key, v_hash|
			v_hash.each do |k, v|
				v_hash[k] = humanize v
			end
		end
	end

	def home
		client = OAuth2::Client.new(ENV['42_UID'], ENV['42_SECRET'], site: "https://api.intra.42.fr")
		token = client.client_credentials.get_token

		@user_info = token.get("/v2/users?filter[login]=alallema").parsed
		first_page = token.get("/v2/users/alallema/locations", params: {page: {size: 100}})
		@logtimes_array = first_page.parsed

		last = /<.+=(\d)>; rel="last"/.match(first_page.headers["link"])
		if last
			i = 2
			while i <= last[1].to_i do
				sleep(1)
				next_page = token.get("/v2/users/alallema/locations", params: {page: {size: 100, number: i}})
				@logtimes_array += next_page.parsed
				i += 1
			end	
		end
		parse_yearbyyear @logtimes_array
		parse_allinone @logtimes_array
		parse_trimestre @logtimes_array
	end

end
