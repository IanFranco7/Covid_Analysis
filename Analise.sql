
--Selecionando os dados

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths 
where continent is not null
order by 1,2

--Países com maior taxa de Infecção comparado a população

select Location, population, Max(total_cases) as HighestInfectionCount, (CONVERT(float, Max(total_cases)) /NULLIF(CONVERT(float, population), 0))*100 as ContaminedPercentage
from PortfolioProject..CovidDeaths 
--where location like '%brazil%'
where continent is not null
group by location, population
order by ContaminedPercentage desc

-- Números Globais

select sum(cast(new_cases as float)) as TotalCases, sum(cast(new_deaths as float)) as TotalDeaths, 
sum(cast(new_deaths as float))/Nullif(sum(cast(new_cases as float)),0)*100 as DeathPercentage
from PortfolioProject..CovidDeaths 
--where location like '%brazil%'
where continent is not null
--group by date
order by 1,2

--looking at total Population vs Vaccinations

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

--Comparando média de mortes global x média de mortes de cada país e ver qual está acima ou abaixo

With CTE_TESTE as ( 
	select continent, location,
Max(cast(total_deaths as float)) as MaxDeathForCountry,
avg(cast(total_deaths as float)) as DeathMediaForLocation,
	(
		select AVG(cast(total_deaths as float)) 
		FROM PortfolioProject..CovidDeaths
	) as media_global_mortes
from PortfolioProject..CovidDeaths
where continent is not null
group by location, continent
)
select *,
case
	when ct.DeathMediaForLocation > ct.media_global_mortes then 'Acima da média'
	when ct.DeathMediaForLocation < ct.media_global_mortes then 'Abaixo da média'
end as MeanCompare
from CTE_TESTE as ct
order by 4 desc


----------------


Select
    cv.location AS pais,
    cv.continent AS continent,
    MAX(cv.median_age) AS media,
    MAX(cv.aged_65_older) AS older65,
    MAX(cv.aged_70_older) AS older70,
    MAX(cd.max_total_deaths) AS total_deaths
FROM PortfolioProject..CovidVaccinations cv
JOIN (
    SELECT
        location,
        MAX(cast(total_deaths as float)) AS max_total_deaths
    FROM PortfolioProject..CovidDeaths
    GROUP BY location
) cd ON cv.location = cd.location
WHERE cv.continent IS NOT NULL
GROUP BY cv.location, cv.continent
order by 3 desc

--Procedure para ver os dados separados por anos e mes, de novos casos e mortes, além de ser possível pegar dados de um país especifico passando parâmetros

create procedure comparisonBetweenDeathsAndCasesByMonths
@country nvarchar(100) = null
as
begin
select continent,
location,
DATEPART(year, date) as ano, 
DATEPART(month, date) as mes,
isnull(sum(cast(new_cases as float)),0) as new_Cases,
isnull(sum(cast(new_deaths as float)),0) as new_Deaths,
isnull(sum(cast(total_cases as float)),0) as total_Cases,
isnull(sum(cast(total_deaths as float)),0) as total_Deaths
from PortfolioProject..CovidDeaths
where continent is not null and (@country is null or location = @country)
group by continent, location, DATEPART(year, date), DATEPART(month, date)
order by location, DATEPART(year, date), DATEPART(month, date)
end

exec comparisonBetweenDeathsAndCasesByMonths @country = 'Brazil'

--Vendo se os países em que mais morreram foram os que tiveram o maior número de casos?

WITH TotalDeathsAndCases AS
(
    SELECT
        continent,
        location,
        MAX(CAST(total_cases AS FLOAT)) AS max_total_cases,
        MAX(CAST(total_deaths AS FLOAT)) AS max_total_deaths
    FROM PortfolioProject..CovidDeaths
    WHERE continent IS NOT NULL
    GROUP BY continent, location
)
SELECT
    location,
    MAX(max_total_cases) AS max_total_cases,
	MAX(max_total_deaths) AS max_total_deaths,
	rank() over(order by Max(max_total_cases) desc) as rank_Cases,
	rank() over(order by Max(max_total_deaths) desc) as rank_Deaths
FROM TotalDeathsAndCases
GROUP BY location
ORDER BY max_total_cases DESC;