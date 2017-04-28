select MV_TIMESTAMP, COUNT(MV_TIMESTAMP) 
from vv_mastervalues 
where MV_TIMESTAMP>'20170427 13:00:00'
group by MV_TIMESTAMP order by MV_TIMESTAMP desc

select count(*) from vv_mastervalues 
where MV_TIMESTAMP>'20170427 13:00:00'

delete vv_mastervalues 
where MV_TIMESTAMP>'20170427 13:00:00'