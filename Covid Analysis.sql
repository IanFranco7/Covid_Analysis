
--Select Data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths 
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contrct covid in your country

select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
from PortfolioProject..CovidDeaths 
where location like '%brazil%'
and continent is not null
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

select Location, date, population, total_cases, (CONVERT(float, total_cases) /NULLIF(CONVERT(float, population), 0))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths 
where location like '%brazil%'
and continent is not null
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

select Location, population, Max(total_cases) as HighestInfectionCount, (CONVERT(float, Max(total_cases)) /NULLIF(CONVERT(float, population), 0))*100 as ContaminedPercentage
from PortfolioProject..CovidDeaths 
--where location like '%brazil%'
where continent is not null
group by location, population
order by ContaminedPercentage desc

-- Showing Countries with Highest Death Count per Population

	select Location, Max(cast( total_deaths as float)) as TotalDeathCount
	from PortfolioProject..CovidDeaths 
	--where location like '%brazil%'
	where total_deaths is not null
	and continent is not null
	group by location
	order by TotalDeathCount desc

	--LET'S BREAK THINGS DOWN BY CONTINENT

	-- Showing continents with the highest death count

	select continent, Max(cast( total_deaths as float)) as TotalDeathCount
	from PortfolioProject..CovidDeaths 
	--where location like '%brazil%'
	where continent is not null
	group by continent
	order by TotalDeathCount desc


-- GLOBAL NUMBERS

select sum(cast(new_cases as float)) as TotalCases, sum(cast(new_deaths as float)) as TotalDeaths, 
sum(cast(new_deaths as float))/Nullif(sum(cast(new_cases as float)),0)*100 as DeathPercentage
from PortfolioProject..CovidDeaths 
--where location like '%brazil%'
where continent is not null
--group by date
order by 1,2

--looking at total Population vs Vaccinations
--USE CTE
with PopvsVac (Continet, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as  RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVccinated
from PopvsVac

-- Temp Table
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as  RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
from #PercentPopulationVaccinated

--creating view to store data for later visualizations

create view PercentPeopleVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as  RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join  PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * 
from PercentPeopleVaccinated