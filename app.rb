require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

#Инициализируем глобальную переменную, и создается бд, если ее не было
def init_rb
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

#before вызывается каждый раз при перезагрузке страницы
before do
	#Инициализация бд
	init_rb
end

#configure вызывается каждый раз при конфигурации приложения, изменении кода и перезагрузки страницы
configure do
	init_rb
	@db.execute 'CREATE TABLE IF NOT EXISTS Post 
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT
	)'
		#post_id это привязка комментария к посту
	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT, 
		created_date DATE, 
		content TEXT,
		post_id INTEGER
	)'
end

get '/' do
	#Выбираем список постов из бд
	@results = @db.execute 'select * from Post order by id desc'
	erb :index
end

#Обработчик get запроса /new 
#Браузер получает страницу с сервера
get '/new' do
	erb :new
end

#Обработчик post запроса /new
#браузер отпарвляет данные на сервер
#erb просто без : загружает каркас страницы с layout
post '/new' do
	content = params[:content]

	#валидация параметра
	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end
	
	#Вместо ? подставится значение из массива потом и сохраняем в бд
	@db.execute 'insert into Post (content, created_date) values (?, datetime())', [content]
	
	#перенаправление на главную страницу
	redirect to '/'
end

#Вывод информации о посте
#Универсальный обработчик для всех постов, преобразует все что после / в нашу переменную, и дальше делаем что хотим
get '/details/:post_id' do

	#Получаем переменную из URL(она динамическая, в зависимости от id комментария)
	post_id = params[:post_id]

	#Получаем список постов (у нас будет только 1 пост)
	results = @db.execute 'select * from Post where id = ?', [post_id]
		
	#Выбираем только этот один пост в переменную @row
	@row = results[0]

	#Выбираем комментарий для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]
	
	#Возвращаем предтсавление
	erb :details
end

#обработчик post запроса 
#браузер отправляет данные на сервер, мы их принимаем
post '/details/:post_id' do
	
	#Получаем переменную из URL
	post_id = params[:post_id]

	#Получаем переменную из POST запроса
	content = params[:content]

	@db.execute 'insert into Comments 
	(
		content, 
		created_date, 
		post_id
	) 
		values 
	(
		?,
		datetime(),
		?
	)', [content, post_id]

	#Перенаправляем на страницу поста
	redirect  to ('/details/' + post_id)
end