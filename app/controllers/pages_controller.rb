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


	def parse_allinone logtimes
		@allinone = Hash.new
		month_base = {"Jan" => 0, "Feb" => 0, "Mar" => 0, "Apr" => 0, "May" => 0, "Jun" => 0, "Jul" => 0, "Aug" => 0, "Sep" => 0, "Oct" => 0, "Nov" => 0, "Dec" => 0}
		month_empty = month_base.clone
		tmp = 0

		# logtimes.push(0)
		logtimes.each do |val|
			# if val != 0
				dbt = Time.parse(val['begin_at'])
				if val['end_at'] == nil
					fin = Time.now
				else
					fin = Time.parse(val['end_at'])
				end
			# end

			key = dbt.month.to_s + " " + dbt.year.to_s
			if @allinone[key] == nil
				@allinone[key] = 0
			end
			@allinone[key] += (fin - dbt).to_i
			# if val == 0 || (tmp != 0 and dbt and tmp != dbt.year)
				# @allinone[tmp] = month_empty
				# month_empty = month_base.clone
			# end
			# if val != 0
			# 	tmp = dbt.year
			# 	month_empty[month_empty.keys[dbt.month - 1]] += (fin - dbt).to_i # sum this val in the month_empty array
			# end
		end
		# logtimes.pop

		@allinone.each do |key, v_hash|
			# v_hash.each do |k, v|
				@allinone[key] = humanize v_hash
			# end
		end
	end


	def parse_yearbyyear logtimes
		@yearbyyear = Hash.new
		month_base = {"Jan" => 0, "Feb" => 0, "Mar" => 0, "Apr" => 0, "May" => 0, "Jun" => 0, "Jul" => 0, "Aug" => 0, "Sep" => 0, "Oct" => 0, "Nov" => 0, "Dec" => 0}
		month_empty = month_base.clone
		tmp = 0

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

		@user_info = token.get("/v2/users?filter[login]=gfrocrai").parsed
		first_page = token.get("/v2/users/gfrocrai/locations", params: {page: {size: 100}})
		@logtimes_array = first_page.parsed

		last = /<.+=(\d)>; rel="last"/.match(first_page.headers["link"])
		if last
			i = 2
			while i <= last[1].to_i do
				sleep(1)
				next_page = token.get("/v2/users/gfrocrai/locations", params: {page: {size: 100, number: i}})
				@logtimes_array += next_page.parsed
				i += 1
			end	
		end
		# parse_yearbyyear @logtimes_array
		parse_allinone @logtimes_array
	end

end
