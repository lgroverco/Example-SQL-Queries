--Select necessary data
SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM PortfolioProjectCovid..CovidDeaths
ORDER BY 1,2

--Percentage of covid cases that result in death
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS mortality_percentage
FROM PortfolioProjectCovid..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Looking at total cases vs population
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS pop_cases_percent
FROM PortfolioProjectCovid..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Countries with highest infection percentage
SELECT 
	location,
	MAX(total_cases) AS highest_infection_count,
	population,
	(MAX(total_cases)/population)*100 AS pop_cases_percent
FROM PortfolioProjectCovid..CovidDeaths
GROUP BY location, population
ORDER BY pop_cases_percent DESC

--Countries with highest mortality numbers
SELECT 
	location,
	MAX(CAST(total_deaths as int)) AS total_death_count
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC

--continent mortality numbers
SELECT 
	location,
	MAX(CAST(total_deaths as int)) AS total_death_count
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY total_death_count DESC


--global
SELECT 
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths as int)) AS total_deaths,
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS mortality_percent
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Generate a rolling count of vaccinations per country
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
	
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Use the rolling count CTE to examine percentage of the population that has been vaccinated day by day
WITH Pop_v_Vac(Continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,(rolling_vaccinations/population)*100 as rolling_vax_percent
FROM pop_v_vac
ORDER BY 1,2;

--temp table to do the same as above
DROP TABLE if exists #PercentPopulationVacciniated
CREATE TABLE #PercentPopulationVacciniated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVacciniated
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,(rolling_vaccinations/population)*100 as rolling_vax_percent
FROM #PercentPopulationVacciniated

--Creating view to store data for visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL;
