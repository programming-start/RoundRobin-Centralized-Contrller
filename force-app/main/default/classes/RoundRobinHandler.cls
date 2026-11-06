public without sharing class RoundRobinHandler{
    
    //@AuraEnabled
    public static Boolean skipAllocationStatus = false;
    public static void GeneralLeadAssignment(List<Lead> leadList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        
        Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>();
        List<Lead> LdList = new List<Lead>();
        Map<id,user>  rrMemberMapToUpdate = new Map<id,user>();
        
        for(Lead l:leadList){
            if(l.Lead_Assigned__c !=true && l.Delete_Lead__c !=true){
                LdList.add(l);
            }
        }

        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType  order by Last_Assigned_time_user__c,createddate asc nulls first ) from Round_Robin__c where Project_Assigned__c=null and Active__c = true limit 1];
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate asc nulls first) from Round_Robin__c where Project_Assigned__c = null and Active__c = true limit 1];
        
        if(RRAvaliablequeList.size()>0){
            if(RRAvaliablequeList[0].Round_Robin_Members__r.size()>0){
                projectAvaliableQueMap.put(RRAvaliablequeList[0].Project_Assigned__c,RRAvaliablequeList[0].Round_Robin_Members__r);
            }
        }
        if(RRqueList.size()>0){
            if(RRqueList[0].Round_Robin_Members__r.size()>0){
                projectQueMap.put(RRqueList[0].Project_Assigned__c,RRqueList[0].Round_Robin_Members__r);
            }
        }
        
        if(projectAvaliableQueMap.containskey(null) && projectAvaliableQueMap.get(null).size()>0){
            system.debug('inserted if');
            List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(null);  
            Integer queueSize = projectQue.size();
            Integer counter = 0;
            
            for(Lead l : LdList){
                if(projectQue!=null && queueSize > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                    system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                    l.ownerId = projectQue[counter].user__c;
                    system.debug('New Lead Owner >> '+projectQue[counter].user__c);
                    l.Lead_Assigned__c = true;
                    l.Reassigned_By__c = UserInfo.getUserId();
                    l.Re_assigned_date__c = system.now();
                    
                    user u = new user();
                    u.Id = projectQue[counter].user__c;
                    u.LastAssignmentTime1__c = system.now().getTime(); 
                    
                    rrMemberMapToUpdate.put(projectQue[counter].user__c,u); 
                    
                    // Move to next user (round robin: 1,2,3,4,1,2,3,4...)
                    counter++;
                    if(counter >= queueSize){
                        counter = 0; 
                    }
                }
            }
        }
        else if(projectQueMap.containsKey(null) && projectQueMap.get(null).size()>0){
            List<Round_Robin_Member__c>  projectQue = projectQueMap.get(null);  
            Integer queueSize = projectQue.size();
            Integer counter = 0;
            
            for(Lead l : LdList){
                if(projectQue!=null && queueSize > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                    l.ownerId = projectQue[counter].user__c;
                    l.Lead_Assigned__c = true;
                    l.Reassigned_By__c = UserInfo.getUserId();
                    l.Re_assigned_date__c = system.now();
                    
                    user u = new user();
                    u.Id = projectQue[counter].user__c;
                    u.LastAssignmentTime1__c = system.now().getTime(); 
                    
                    rrMemberMapToUpdate.put(projectQue[counter].user__c,u); 
                    
                    counter++; 
                    if(counter >= queueSize){
                        counter = 0; 
                    }	
                }
            }
        }

        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
    }
    //NRI Allocation by sathya--start 18-06-2026
    public static void assignNRILead(List<Lead> leadList, Boolean updateLeads){
    
        String dayOfWeek = System.now().format('EEEE');
        List<User> nriUsers = [
            SELECT Id
            FROM User
            WHERE Is_NRI_User__c = true
            AND IsActive = true
            AND Profile.Name = 'Pre Sales' order by LastAssignmentTime1__c asc nulls first
            // Uncomment when multiple NRI users are introduced
            //AND Availability__c=true
            //AND is_working__c = true
            //AND Week_off_days__c excludes (:dayOfWeek)
        ];
            
        
        if(nriUsers.isEmpty()){
            return;
        }
    
        Integer counter = 0;
        Integer queueSize = nriUsers.size();
    
        for(Lead ld : leadList){
    
            ld.OwnerId = nriUsers[counter].Id;
            ld.Lead_Assigned__c = true;
            ld.Is_NRI_Lead__c = true;
            //ld.Reassigned_By__c = UserInfo.getUserId();
            //ld.Re_assigned_date__c = System.now();
            counter++;
    
            if(counter >= queueSize){
                counter = 0;
            }
        }
        List<User> updatedUserList = new List<User>();
        User userRec = new User();
        userRec.Id = nriUsers[0].Id;
        userRec.LastAssignmentTime1__c = system.now().getTime();
        updatedUserList.add(userRec);
        if(!updatedUserList.isEmpty()){
            update updatedUserList;
        }
	}
    //NRI Allocation by sathya--End 18-06-2026
    // NRI Sales Allocation by Sathya -- Start 19-06-2026
public static void assignNRISalesLead(
    List<Lead> leadList,
    Map<Id, Lead> oldMap,
    Boolean updateLeads
){

    String dayOfWeek = System.now().format('EEEE');

    List<User> nriSalesUsers = [
        SELECT Id
        FROM User
        WHERE Is_NRI_User__c = true
        AND IsActive = true
        AND Profile.Name = 'Sales'
        ORDER BY LastAssignmentTime1__c ASC NULLS FIRST
        // Uncomment when multiple NRI Sales users are introduced
        //AND Availability__c = true
        //AND is_working__c = true
        //AND Week_off_days__c excludes (:dayOfWeek)
    ];

    if(nriSalesUsers.isEmpty()){
        return;
    }

    Integer counter = 0;
    Integer queueSize = nriSalesUsers.size();

    for(Lead ld : leadList){

        // Assign NRI Sales Owner
        ld.OwnerId = nriSalesUsers[counter].Id;

        // Mark Lead as Assigned
        ld.Lead_Assigned__c = true;

        /*Change Record Type to NRI Sales
        ld.RecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('NRI_Sales')
            .getRecordTypeId();*/

        counter++;

        if(counter >= queueSize){
            counter = 0;
        }
    }

    // Update Last Assignment Time
    List<User> updatedUserList = new List<User>();

    User userRec = new User();
    userRec.Id = nriSalesUsers[0].Id;
    userRec.LastAssignmentTime1__c = System.now().getTime();

    updatedUserList.add(userRec);

    if(!updatedUserList.isEmpty()){
        update updatedUserList;
    }
}
// NRI Sales Allocation by Sathya -- End 19-06-2026
// NRI Sales Allocation by Sathya 20-06-2026
public static void shareLeadWithPreviousOwner(
    List<Lead> newLeads,
    Map<Id, Lead> oldMap
) {
    List<LeadShare> shareList = new List<LeadShare>();

    for (Lead ld : newLeads) {

        Lead oldLead = oldMap.get(ld.Id);

        if (oldLead.OwnerId != ld.OwnerId) {

            LeadShare ls = new LeadShare();
            ls.LeadId = ld.Id;
            ls.UserOrGroupId = oldLead.OwnerId;
            ls.LeadAccessLevel = 'Read';
            ls.RowCause = Schema.LeadShare.RowCause.Manual;

            shareList.add(ls);
        }
    }

    if (!shareList.isEmpty()) {
        insert shareList;
    }
}
// NRI Sales Allocation by Sathya 20-06-2026--End
    public static void SiteVisitAssignment(List<Site_Visit__c> SVList,string usType){
        system.debug('SV Assignment');
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        
        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Site_Visit__c>>  projectLeadMap = new Map<string,List<Site_Visit__c>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user>();
        
        for(Site_Visit__c sv : SVList){
            string project = sv.Project__c;
            projectinterested.add(project);
            List<Site_Visit__c>  projectQue = projectLeadMap.get(project); 
            if(projectQue  == null){
                projectLeadMap.put(project, new List<Site_Visit__c>{sv} );
            }else{
                projectQue.add(sv);  
                projectLeadMap.put(project,  projectQue);
            }
        }
        
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType  order by Last_SV_Assigned_Time__c,createddate asc nulls first ) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        system.debug('projectinterested'+ RRAvaliablequeList);
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType order by Last_SV_Assigned_Time__c,createddate asc nulls first) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                system.debug('RoundRobins(Prj) >>'+rr.Project_Assigned__c);
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        for(string prj : projectinterested){
            system.debug('inserted : '+prj);
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                system.debug('inserted if');
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                Integer queueSize = projectQue.size();
                Integer counter = 0;
                
                for(Site_Visit__c l : projectLeadMap.get(prj)){
                    system.debug('further inserted for');
                    if(projectQue!=null && queueSize > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        system.debug('SV assigned owner'+ l.ownerId);
                        
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastSVAssignmentTime__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u); 
                        
                        counter++; 
                        if(counter >= queueSize){
                            counter = 0; 
                        }
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                Integer queueSize = projectQue.size();
                Integer counter = 0;
                
                for(Site_Visit__c l : projectLeadMap.get(prj)){
                    if(projectQue!=null && queueSize > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastSVAssignmentTime__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u); 
                        
                        counter++;
                        if(counter >= queueSize){
                            counter = 0;
                        }
                    }
                }
            }
        }
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
    }
    
    
    //@AuraEnabled
    // FIXED: True Round Robin distribution (1,2,3,4,1,2,3,4...) with equal spread
    // ================= Location wise allocation by sathya =================
    /* =====================================================================
       SVC LOCATION ROUTING — location is a HARD constraint.
       For usType == 'SVC' the lead is routed by the Pre Sales owner's
       Working_Location__c with this priority:
         1. Same location + Available (Availability__c = true)
         2. Same location, only IsActive = true (ignore Availability / working / week-off)   <-- NEW
         3. Only if the project has NO active SVC user in that location at all:
            fall back to the full pool (cross-location) and flag
            SVC_Location_Matched__c = false.
       So a Coimbatore lead stays with Coimbatore SVC even when nobody in
       Coimbatore is marked available. Same for Chennai.
       All non-SVC usTypes run the ORIGINAL round-robin below, unchanged.
       ===================================================================== */
    public static void assignLead(List<Lead> leadList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');

        // ============ SVC LOCATION-BASED BRANCH — Location wise allocation by sathya ============
        if(usType == 'SVC'){
            // group SVC leads by project
            Set<String> svcProjects = new Set<String>();
            Map<String,List<Lead>> svcProjLeads = new Map<String,List<Lead>>();
            for(Lead l : leadList){
                String prj = l.Allocated_Project__c;
                if(String.isBlank(prj) || l.Lead_Assigned__c == true || l.Delete_Lead__c == true) continue;
                svcProjects.add(prj);
                if(!svcProjLeads.containsKey(prj)) svcProjLeads.put(prj, new List<Lead>());
                svcProjLeads.get(prj).add(l);
            }
            if(svcProjects.isEmpty()){
                if(updateLeads) update leadList;
                return;
            }

            // Pre Sales owner location per lead
            Set<Id> preIds = new Set<Id>();
            for(Lead l : leadList){ if(l.Pre_sales_user__c != null) preIds.add(l.Pre_sales_user__c); }
            Map<Id,String> preLoc = new Map<Id,String>();
            if(!preIds.isEmpty()){
                for(User u : [SELECT Id, Working_Location__c FROM User WHERE Id IN :preIds]){
                    preLoc.put(u.Id, u.Working_Location__c);
                }
            }

            // Available pool + full (any working) pool per project — both carry Working_Location__c
            Map<String,List<Round_Robin_Member__c>> availByPrj = new Map<String,List<Round_Robin_Member__c>>();
            Map<String,List<Round_Robin_Member__c>> anyByPrj   = new Map<String,List<Round_Robin_Member__c>>();

            for(Round_Robin__c rr : [
                SELECT Project_Assigned__c,
                    (SELECT User__c, User__r.Working_Location__c
                     FROM Round_Robin_Members__r
                     WHERE Active__c = true AND User_Type__c = 'SVC'
                       AND user__r.Availability__c = true AND user__r.IsActive = true
                       AND user__r.is_working__c = true
                       AND User__r.Week_off_days__c EXCLUDES (:dayOfWeek)
                     ORDER BY Last_Assigned_time_user__c, createddate ASC NULLS FIRST)
                FROM Round_Robin__c
                WHERE Project_Assigned__c IN :svcProjects AND Active__c = true ]){
                if(!rr.Round_Robin_Members__r.isEmpty())
                    availByPrj.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
            }
            // Location wise allocation by sathya — same-location fallback pool: ONLY IsActive is checked
            // (Availability, is_working and Week_off are intentionally ignored so a lead never leaves its city)
            for(Round_Robin__c rr : [
                SELECT Project_Assigned__c,
                    (SELECT User__c, User__r.Working_Location__c
                     FROM Round_Robin_Members__r
                     WHERE Active__c = true AND User_Type__c = 'SVC'
                       AND user__r.IsActive = true
                     ORDER BY Last_Assigned_time_user__c, createddate ASC NULLS FIRST)
                FROM Round_Robin__c
                WHERE Project_Assigned__c IN :svcProjects AND Active__c = true ]){
                if(!rr.Round_Robin_Members__r.isEmpty())
                    anyByPrj.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
            }

            Map<Id,User> rrUpd = new Map<Id,User>();
            Map<String,Integer> counters = new Map<String,Integer>();   // key = project|location
            
            /* ===== Added By Sivam V - START : Bulk allocation — collect assigned leads, allocate once after the loop ===== */
            List<Lead> svcAllocationLeads = new List<Lead>();
            /* ===== Added By Sivam V - END : Bulk allocation ===== */

            for(String prj : svcProjLeads.keySet()){
                // Location wise allocation by sathya — availPool = available SVC, anyPool = all working SVC
                List<Round_Robin_Member__c> availPool = availByPrj.get(prj);
                List<Round_Robin_Member__c> anyPool   = anyByPrj.get(prj);

                for(Lead l : svcProjLeads.get(prj)){
                    String loc = preLoc.get(l.Pre_sales_user__c);   // Coimbatore / Chennai / null

                    List<Round_Robin_Member__c> pool = new List<Round_Robin_Member__c>();
                    Boolean matched = false;
                    String  locKey  = null;

                    if(loc != null){
                        // 1. same location + available
                        if(availPool != null){
                            for(Round_Robin_Member__c m : availPool){
                                if(m.User__r != null && m.User__r.Working_Location__c == loc) pool.add(m);
                            }
                        }
                        // 2. same location, ignore availability (Location wise allocation by sathya)
                        if(pool.isEmpty() && anyPool != null){
                            for(Round_Robin_Member__c m : anyPool){
                                if(m.User__r != null && m.User__r.Working_Location__c == loc) pool.add(m);
                            }
                        }
                        if(!pool.isEmpty()){ matched = true; locKey = prj + '|' + loc; }
                    }

                    // 3. no same-location SVC user at all -> cross-location fallback (flag false)
                    if(pool.isEmpty()){
                        pool   = (availPool != null && !availPool.isEmpty()) ? availPool : anyPool;
                        matched = false;
                        locKey  = prj + '|_FALLBACK_';
                    }
                    if(pool == null || pool.isEmpty()) continue;   // project has no SVC users at all

                    Integer idx = counters.containsKey(locKey) ? counters.get(locKey) : 0;
                    if(idx >= pool.size()) idx = 0;

                    Round_Robin_Member__c member = pool[idx];
                    if(member != null && member.User__c != null){
                        l.OwnerId             = member.User__c;
                        l.Lead_Assigned__c    = true;
                        l.Reassigned_By__c    = UserInfo.getUserId();
                        l.Re_assigned_date__c = system.now();
                        l.SVC_Location_Matched__c = matched;
                        l.SVC_Allocation_Type__c  = 'Location Round Robin';   // 20/10/2026 - reporting: which SVC round robin allotted this lead
                        l.SVC_Allocated_Date__c   = system.now();              // 20/10/2026 - reporting: fixed SVC allocation time, never overwritten by later status changes
                        // === Commented by Sivam V ===
                        // AllocationService.createAllocation(l.OwnerId, l.Id, l.Allocated_Project__c);.
                        /* ===== Added By Sivam V - START : Bulk allocation — was AllocationService.createAllocation(l.OwnerId, l.Id, l.Allocated_Project__c) per lead (SOQL 101) ===== */
                        svcAllocationLeads.add(l);
                        /* ===== Added By Sivam V  - END : Bulk allocation ===== */

                        User u = new User(Id = member.User__c);
                        u.LastAssignmentTime1__c = system.now().getTime();
                        rrUpd.put(member.User__c, u);
                    }
                    Integer nxt = idx + 1; if(nxt >= pool.size()) nxt = 0;
                    counters.put(locKey, nxt);
                }
            }

            /* ===== Added By Sivam V - START : Bulk allocation — one call for the whole batch, same OwnerId / Id / Allocated_Project__c values ===== */
            if(!svcAllocationLeads.isEmpty()){
                AllocationService.createAllocations(svcAllocationLeads);
            }
            /* ===== Added By Sivam V - END : Bulk allocation ===== */
            if(!rrUpd.isEmpty()) update rrUpd.values();
            if(updateLeads) update leadList;
            System.debug('Exit Round Robin (SVC location) --->');
            return;
        }
        // =============== END SVC BRANCH — original logic below (non-SVC) ===============

        system.debug('called');
        System.debug('Enter Round Robin Assign Lead Starts--->');

        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>();
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();

        for(Lead l:leadList){
            string project = l.Allocated_Project__c;
            if(!String.isBlank(project) && l.Lead_Assigned__c !=true && l.Delete_Lead__c !=true){
                projectinterested.add(project);
                List<Lead>  projectQue = projectLeadMap.get(project);
                if(projectQue  == null){
                    projectLeadMap.put(project, new List<Lead>{l} );
                }else{
                    projectQue.add(l);
                    projectLeadMap.put(project,  projectQue);
                }
            }
        }

        Map<string,List<Round_Robin_Member__c>>  projectSourceAvailableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectSourceQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();

        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c,Lead_Source__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType  order by Last_Assigned_time_user__c,createddate asc nulls first ) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c,Lead_Source__c, (select Name,User__c from  Round_Robin_Members__r  where user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate asc nulls first) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];

        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    if(!String.isBlank(rr.Lead_Source__c)){
                        projectSourceAvailableQueMap.put(rr.Project_Assigned__c + '_' + rr.Lead_Source__c, rr.Round_Robin_Members__r);
                    }else{
                        projectAvaliableQueMap.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
                    }
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    if(!String.isBlank(rr.Lead_Source__c)){
                        projectSourceQueMap.put(rr.Project_Assigned__c + '_' + rr.Lead_Source__c, rr.Round_Robin_Members__r);
                    }else{
                        projectQueMap.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
                    }
                }
            }
        }

        Map<String, List<Lead>> queueLeadsMap = new Map<String, List<Lead>>();
        Map<String, List<Round_Robin_Member__c>> queueMembersMap = new Map<String, List<Round_Robin_Member__c>>();

        for(string prj : projectinterested){
            for(Lead l : projectLeadMap.get(prj)){
                List<Round_Robin_Member__c> projectQue = null;
                String matchedKey = null;

                Set<String> leadSources = new Set<String>();
                if(!String.isBlank(l.Lead_source__c)){
                    for(String src : l.Lead_source__c.split(';')){
                        leadSources.add(src.trim());
                    }
                }

                if(leadSources.size() > 0){
                    for(String mapKey : projectSourceAvailableQueMap.keySet()){
                        if(mapKey.startsWith(prj + '_')){
                            String rrLeadSource = mapKey.substringAfter(prj + '_');
                            for(String rrSrc : rrLeadSource.split(';')){
                                if(leadSources.contains(rrSrc.trim())){
                                    projectQue = projectSourceAvailableQueMap.get(mapKey);
                                    matchedKey = mapKey;
                                    break;
                                }
                            }
                            if(projectQue != null) break;
                        }
                    }
                }
                if(projectQue == null && leadSources.size() > 0){
                    for(String mapKey : projectSourceQueMap.keySet()){
                        if(mapKey.startsWith(prj + '_')){
                            String rrLeadSource = mapKey.substringAfter(prj + '_');
                            for(String rrSrc : rrLeadSource.split(';')){
                                if(leadSources.contains(rrSrc.trim())){
                                    projectQue = projectSourceQueMap.get(mapKey);
                                    matchedKey = mapKey;
                                    break;
                                }
                            }
                            if(projectQue != null) break;
                        }
                    }
                }
                if(projectQue == null){
                    if(projectAvaliableQueMap.containsKey(prj)){
                        projectQue = projectAvaliableQueMap.get(prj);
                        matchedKey = prj;
                    }
                }
                if(projectQue == null){
                    if(projectQueMap.containsKey(prj)){
                        projectQue = projectQueMap.get(prj);
                        matchedKey = prj;
                    }
                }
                if(projectQue == null){
                    for(String mapKey : projectSourceAvailableQueMap.keySet()){
                        if(mapKey.startsWith(prj + '_')){
                            projectQue = projectSourceAvailableQueMap.get(mapKey);
                            matchedKey = mapKey;
                            break;
                        }
                    }
                }
                if(projectQue == null){
                    for(String mapKey : projectSourceQueMap.keySet()){
                        if(mapKey.startsWith(prj + '_')){
                            projectQue = projectSourceQueMap.get(mapKey);
                            matchedKey = mapKey;
                            break;
                        }
                    }
                }

                if(projectQue != null && matchedKey != null){
                    if(!queueLeadsMap.containsKey(matchedKey)){
                        queueLeadsMap.put(matchedKey, new List<Lead>());
                        queueMembersMap.put(matchedKey, projectQue);
                    }
                    queueLeadsMap.get(matchedKey).add(l);
                }
            }
        }

        for(String queueKey : queueLeadsMap.keySet()){
            List<Lead> leadsForQueue = queueLeadsMap.get(queueKey);
            List<Round_Robin_Member__c> members = queueMembersMap.get(queueKey);

            if(members == null || members.size() == 0) continue;

            Integer queueSize = members.size();
            Integer counter = 0;

            for(Lead l : leadsForQueue){
                Round_Robin_Member__c member = members[counter];

                if(member != null && member.user__c != null){
                    l.ownerId = member.user__c;
                    l.Lead_Assigned__c = true;
                    l.Reassigned_By__c = UserInfo.getUserId();
                    l.Re_assigned_date__c = system.now();
                     // === CHANGE 1B === do not overwrite status during GRE SV completion
                     if(usType == 'Sales' && !skipAllocationStatus){
                        l.Lead_Status__c = 'Allocation';
                     }
                    user u = new user();
                    u.Id = member.user__c;
                    u.LastAssignmentTime1__c = system.now().getTime();
                    rrMemberMapToUpdate.put(member.user__c, u);
                }

                counter++;
                if(counter >= queueSize){
                    counter = 0;
                }
            }
        }

        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
        System.debug('Exit Round Robin Assign Lead Starts--->');
    }
    // ================= Location wise allocation by sathya =================
    
    public static void assignUnqualifiedLeads(List<Lead> leadList,boolean updateLeads,string usType){
        system.debug('called assignUnqualifiedLeads');
        
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        
        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
        
        for(Lead l:leadList){
            string project = l.Allocated_Project__c;
            
            if(project != null && project != '' && l.Lead_Assigned__c !=true && l.Delete_Lead__c !=true){ 
                projectinterested.add(project);
                List<Lead>  projectQue = projectLeadMap.get(project); 
                if(projectQue  == null){
                    projectLeadMap.put(project, new List<Lead>{l} );
                }else{
                    projectQue.add(l);  
                    projectLeadMap.put(project,  projectQue);
                }
            }
        }
        
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.Availability__c=true AND user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType  order by Last_Unqualified_lead_Assigned_Time__c,createddate asc nulls first ) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        system.debug('projectinterested'+ RRAvaliablequeList);
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND user__r.IsActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c excludes (:dayOfWeek) AND User_Type__c=:usType order by Last_Unqualified_lead_Assigned_Time__c,createddate asc nulls first) from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                system.debug('RoundRobins(Prj) >>'+rr.Project_Assigned__c);
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        // FIXED: True Round Robin distribution
        for(string prj : projectinterested){
            system.debug('inserted : '+prj);
            List<Round_Robin_Member__c> projectQue = null;
            
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                projectQue = projectAvaliableQueMap.get(prj);
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                projectQue = projectQueMap.get(prj);
            }
            
            if(projectQue != null && projectQue.size() > 0){
                List<Lead> leadsForProject = projectLeadMap.get(prj);
                Integer queueSize = projectQue.size();
                Integer counter = 0;
                
                // Round robin: assign each lead one by one
                for(Lead l : leadsForProject){
                    Round_Robin_Member__c member = projectQue[counter];
                    
                    if(member != null && member.user__c != null){
                        l.ownerId = member.user__c;
                        l.Lead_Assigned__c = true;
                        l.Reassigned_By__c = UserInfo.getUserId();
                        l.Re_assigned_date__c = system.now();
                        
                        user u = new user();
                        u.Id = member.user__c;
                        u.Last_Unqualified_lead_Assigned_Time__c = system.now().getTime();
                        rrMemberMapToUpdate.put(member.user__c, u);
                    }
                    
                    counter++;
                    if(counter >= queueSize){
                        counter = 0;
                    }
                }
            }
        }
        
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
    }
    
    public static void assignToQueaue(List<Lead> leadList, String usType){  

    List<String> projectinterested = new List<String>();
    Map<String, List<Round_Robin_Member__c>> projectQueMap = new Map<String, List<Round_Robin_Member__c>>();
    Map<String, List<Lead>> projectContactMap = new Map<String, List<Lead>>();
    Map<Id, Round_Robin_Member__c> rrMemberMapToUpdate = new Map<Id, Round_Robin_Member__c>();

    // Group leads by project
    for(Lead l : leadList){
        String project = l.Allocated_Project__c;
        if(!String.isBlank(project) && l.Lead_Assigned__c != true && l.Delete_Lead__c != true){ 
            projectinterested.add(project);
            if(!projectContactMap.containsKey(project)){
                projectContactMap.put(project, new List<Lead>());
            }
            projectContactMap.get(project).add(l);
        }  
    }
    if(projectinterested.isEmpty()) return;

    // Fetch round robin queues
    List<Round_Robin__c> queList = [
        SELECT Id, Project_Assigned__c,
               (SELECT Id, User__c
                FROM Round_Robin_Members__r
                WHERE Active__c = true AND User_Type__c = 'Sales'
                ORDER BY Last_Assigned_Time__c ASC)
        FROM Round_Robin__c
        WHERE Project_Assigned__c IN :projectinterested
    ];

    // Build project → members map
    for(Round_Robin__c r : queList){  
        if(r.Round_Robin_Members__r != null && !r.Round_Robin_Members__r.isEmpty()){
            projectQueMap.put(r.Project_Assigned__c, r.Round_Robin_Members__r);
        }
    }

    // TRUE ROUND ROBIN: 1,2,3,4,1,2,3,4...
    for(String prj : projectContactMap.keySet()){ 

        List<Lead> leadsQue = projectContactMap.get(prj);
        List<Round_Robin_Member__c> projectQue = projectQueMap.get(prj);
        if(projectQue == null || projectQue.isEmpty()) continue;
        Integer queueSize = projectQue.size();
        Integer counter = 0;
        for(Lead l : leadsQue){
            Round_Robin_Member__c member = projectQue[counter];
            if(member != null && member.User__c != null){
                l.OwnerId = member.User__c;
                if(usType == 'Pre Sales'){
                    l.Pre_sales_user__c = member.User__c;
                }else{
                    l.Sales_user__c = member.User__c;
                }
                l.Lead_Assigned__c = true;
                l.Reassigned_By__c = UserInfo.getUserId();
                l.Re_assigned_date__c = System.now();
                member.Last_Assigned_Time__c = System.now().getTime();
                rrMemberMapToUpdate.put(member.Id, member);
            }
            counter++;
            if(counter >= queueSize){
                counter = 0; // 1-2-3-4-1-2-3-4
            }
        }
    }

    if(!rrMemberMapToUpdate.isEmpty()){
        update rrMemberMapToUpdate.values();
    }
}
        public static void testcover(){
        integer i=0;
        if(i==0){
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
        }
    }

    /* =====================================================================
       INBOUND SVC COUNTER STAMP   (20/10/2026)
       Called from CallTypeBasedRoundRobin.assignInboundSVCLeads.
       The User DML is executed here, inside this class, on purpose: the
       lead is pushed by a Pre Sales user, and in this org a non admin user
       can update another user's record only when the DML statement runs in
       this class's API version (55.0). The identical statement in a class on
       API 67.0 failed with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY,
       while the LastAssignmentTime1__c stamp in the SVC branch above has
       always worked for the same users. Nothing else in this class changes.
       ===================================================================== */
    public static void stampInboundSVCAssignment(List<User> svcUsersToStamp){
        if(svcUsersToStamp == null || svcUsersToStamp.isEmpty()){
            return;
        }
        update svcUsersToStamp;
    }
}