/* 

Data Cleaning Project in Excel, using housing data from Nashville, TN. 
Skills Highlighted: Data Cleaning, Joins, CTEs, Parsing, Substrings, Windows Functions 

*/


SELECT *
FROM HousingData.dbo.HousingData




-- Populate Property Address Data

SELECT *
FROM HousingData.dbo.HousingData
Order BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.HousingData a
JOIN HousingData.dbo.HousingData b
        on a.ParcelID = b.ParcelID
        and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.HousingData a
JOIN HousingData.dbo.HousingData b
        on a.ParcelID = b.ParcelID
        and a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL




-- Convert PropertyAddress to individual columns for Adddress, City, and State

SELECT PropertyAddress
FROM HousingData.dbo.HousingData

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM HousingData.dbo.HousingData

Alter TABLE HousingData
Add PropertySplitAddress NVARCHAR(255)

Update HousingData
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

Alter TABLE HousingData
Add PropertySplitCity NVARCHAR(255)

Update HousingData
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))




-- Convert OwnerAddress to individual columns for Adddress, City, and State

SELECT OwnerAddress
FROM HousingData.dbo.HousingData

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM HousingData.dbo.HousingData

Alter TABLE HousingData
Add OwnerSplitAddress NVARCHAR(255)

Update HousingData
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Alter TABLE HousingData
Add OwnerSplitCity NVARCHAR(255)

Update HousingData
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Alter TABLE HousingData
Add OwnerSplitState NVARCHAR(255)

Update HousingData
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)




-- Change Y and N to Yes and No in "Sold as Vacant" column

SELECT Distinct(SoldAsVacant), count(SoldAsVacant)
FROM HousingData.dbo.HousingData
Group BY SoldAsVacant
Order BY 2

SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'YES'
        When SoldAsVacant = 'N' THEN 'NO'
        Else SoldAsVacant
        END
FROM HousingData.dbo.HousingData

Update HousingData
Set SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'
        When SoldAsVacant = 'N' THEN 'NO'
        Else SoldAsVacant
        END




-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From HousingData.dbo.HousingData
)
DELETE
From RowNumCTE
Where row_num > 1




-- Delete Unnecessary Columns

SELECT *
FROM HousingData.dbo.HousingData

ALTER TABLE HousingData.dbo.HousingData
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate