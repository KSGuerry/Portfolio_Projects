
select * from portfolio_project_1..covid_deaths
	order by 3,4;

select * from portfolio_project_1..covid_deaths
	where location = 'united states'
	order by 3,4;

select * from portfolio_project_1..covid_vaccinations
	order by 3,4;

-- Select data that we are going to be using

select location,
	   date,
	   total_cases,
	   new_cases,
	   total_deaths,
	   population
	   from covid_deaths
	   order by location, date; -- order by 1,2

-- Looking at total cases vs total deaths
-- Shows the chances of dying if you contract covid in x country
select location,
	   date,
	   total_cases,
	   total_deaths,
	   round((total_deaths/total_cases) * 100, 2) as death_percentage
	   from covid_deaths
	   where location like '%states%'
	   order by location, date;

-- Looking at total cases vs population
-- Shows what percentage of population in x country contracted covie
select location,
	   date,
	   total_cases,
	   population,
	   round((total_cases/population) * 100, 2) as contraction_percentage
	   from covid_deaths
	   where location like '%states%'
	   order by location, date;

-- What countries have the highest infection rates compared to population?
select location,
	   population,
	   max(total_cases) as total_cases,
	   round(max((total_cases/population)) * 100, 2) as contraction_percentage
	   from covid_deaths
	   group by location, population
	   order by contraction_percentage desc;

-- Shows the countries with the highest death count per population
select location,
	   max(cast(total_deaths as int)) as total_deaths
	   from covid_deaths
	   where continent is not null -- need this to eliminate world, asia, north america, etc.
	   group by location
	   order by total_deaths desc;

-- Break things down by continent. Showing the continets with the highest death count
select continent, -- seems to have problems - north america not including canada
	   max(cast(total_deaths as int)) as total_deaths
	   from covid_deaths
	   where continent is not null
	   group by continent
	   order by total_deaths desc;

select location,
	   max(cast(total_deaths as int)) as total_deaths
	   from covid_deaths
	   where continent is null
			 and location not in ('World', 'European Union')
	   group by location
	   order by total_deaths desc;

-- Global Numbers
select sum(new_cases) as total_cases,
	   sum(cast(new_deaths as int)) as total_deaths,
	   round(sum(cast(new_deaths as int))/sum(new_cases) * 100, 2) as total_death_pct
	   from covid_deaths
	   where continent is not null;

-- Looking at total population vs vaccinations
with pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_new_vaccinations) as (
	
select dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_new_vaccinations
	   from covid_deaths dea
	   join covid_vaccinations vac
			on dea.location = vac.location
			and dea.date = vac.date
	   where dea.continent is not null
)
select *,
	   round((rolling_new_vaccinations/population) * 100, 2) as rolling_vaccination_percent
	   from pop_vs_vac;

-- Temp Table Way
drop table if exists #percent_pop_vaccinated;

create table #percent_pop_vaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_new_vaccinations numeric
	)

insert into #percent_pop_vaccinated
	select dea.continent,
			  dea.location,
			  dea.date,
			  dea.population,
			  vac.new_vaccinations,
			  sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_new_vaccinations
			  from covid_deaths dea
			  join covid_vaccinations vac
				   on dea.location = vac.location
				   and dea.date = vac.date
			  where dea.continent is not null

select *,
	   round((rolling_new_vaccinations/population) * 100, 2) as rolling_vaccination_percent
	   from #percent_pop_vaccinated;


-- View for later visualizations
create view v_percent_pop_vaccinated as
	select dea.continent,
			  dea.location,
			  dea.date,
			  dea.population,
			  vac.new_vaccinations,
			  sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date) as rolling_new_vaccinations
			  from covid_deaths dea
			  join covid_vaccinations vac
				   on dea.location = vac.location
				   and dea.date = vac.date
			  where dea.continent is not null


select * from v_percent_pop_vaccinated;
