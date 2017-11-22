<#
.SYNOPSIS
    Gets all the singles results from an event from smash.gg
.DESCRIPTION
    Gets all the singles results from an event from smash.gg
    This is done by querying the smash.gg api in which you can with the tournament name query all the information to the tournament.
    With a series of rest calls information needed will be gotten from the website
    The data structure of the api allows multiple calls and lets you go in to detail for each object
    This then as a output gives 6 arrays which then can be put together in to one database
.NOTES
    File Name  : Install-WinRmAzureVmCert.ps1
    Author     : Andreas Scherer - a.scherer1996@hotmail.com
.PARAMETER SubscriptionName
    The name of the Azure subscription whose VMs you want to get
    certificates from. Use quotes around subscription names
    containing spaces.
.PARAMETER ServiceName
    The name of the Azure cloud service the virtual machine is
    deployed in.
.PARAMETER VmName
    The name of the Azure virtual machine to install the 
    certificate for. 
.EXAMPLE
    Install-WinRmAzureVMCert -SubscriptionName "my subscription" `
            -ServiceName "mycloudservice" -Name "myvm1" 
#>

#Import all the tags of the players in the possible pr
$playerarray = Import-Csv C:\Users\Andi\Desktop\562PR.csv 
$playerarray | Sort-Object -Property PLayerTags

#Import all the tournaments regarded for the PR
$Tournaments = Import-Csv C:\Users\Andi\Desktop\tournamentname.csv

Function Query-Tournamentinfo{
    
    Param(
    [string]$TournamentLinkString
    )

    #Arrues flushen
    $SeedArray = $null
    $PLayerArray = $null
    $PhaseArray = $null
    $PhaseGroupArray = $null
    $SetArray = $null
    $StandingsArray = $null

    Write-Host $TournamentLinkString

    #Tournament URL definition
    $TournamentUri =  $("https://api.smash.gg/tournament/" + $TournamentLinkString + "/event/melee-singles?expand[]=phase&expand[]=groups")

    

    #Call auf das smash.gg api
    $TournamentResponse = Invoke-RestMethod -Uri $TournamentUri

    #Foreach Tournament alle events auslesen
    #Events sind singles, doubles, crews etc
    Foreach( $TournamentEvent in $TournamentResponse.entities.event ){
        
        If( $TournamentEvent.name -ne $null){

            #Checken ob der Event den string singles beinhalted
            If($TournamentEvent.name -like "*Singles*"){

                #Falls ja dann den event seine event ID auslesen für spätere quering 
                $SinglesEventID = $TournamentEvent.Id
            
            Write-host "test1"
            }#End of If($TournamentEvent.name -like "*Singles*")
        write-host "test2"
        }

    write-host "test3"
    }#End of Foreach( $TournamentEvent in $TournamentResponse.entities.event )

    #Checkt ob der singles event gefunden wurde
    if($SinglesEventID -ne $null){
    
        #Rest api call für die event informationen
        $EventUri = $("https://api.smash.gg/event/" + $SinglesEventID + "?expand[]=groups&expand[]=phase" )
        $EventResponse =  Invoke-RestMethod -Uri $Eventuri

        #Einen Array createn für die verschieden phasen des events
        $PhaseArray = @()

        

        #Foreach event phase im event 
        #Event phase ist zum beispiel pools 
        Foreach($EventPhase in $EventResponse.entities.phase){
            
            if($EventPhase.name -notlike "*amateur*"){
                #$AmateurBracketId = $EventPhase.id
            


            #Erstellt ein Phase object für denn event
            $NewPhaseObject = New-Object psobject

            #Adde zum object name, id und tier
            Add-Member -InputObject $NewPhaseObject -MemberType NoteProperty -Name name -Value $EventPhase.name   
            Add-Member -InputObject $NewPhaseObject -MemberType NoteProperty -Name id -Value $EventPhase.id
            Add-Member -InputObject $NewPhaseObject -MemberType NoteProperty -Name tier -Value $EventPhase.tier
        
            #added das object zum phase object array
            $PhaseArray += $NewPhaseObject  
    
            #Erstelle einen phase group array 
            $PhaseGroupArray = @()

            #Foreach Phasegroup im event response
            Foreach($PhaseGroup in $EventResponse.entities.groups){

                    #Erstelle ein Phase group object
                    $NewPhaseGroupObject = New-Object psobject

                    #Adde zum object id, phaseid, grouptype id und sets on deck 
                    Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name groupId -Value $PhaseGroup.id
                    Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name PhaseGroupBelongsToId -Value $PhaseGroup.phaseId
                    Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name groupTypeId -Value $PhaseGroup.GroupTypeId
                    Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name SetesOnDeck -Value $PhaseGroup.setsOnDeck
            
                    #Falls die phase id nicht null ist 
                    if($PhaseGroup.waveId -ne $null){

                        #Adde die wave id zum object
                        Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name waveId -Value $PhaseGroup.waveId
            
                    }#End of if($PhaseGroup.waveId -ne $null)
                    else{
                
                        #Für den fall das die wave einen string beinhalted wird der string final wave geadded
                        Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name waveId -Value "final wave"
            
                    }#End of else($PhaseGroup.waveId -ne $null)

                    #Check ob die winner Target Phase Id leer ist 
                    #Falls es die letzte phase ist also grand final/bracket gibt es keine weitere phase mehr gibt
                    if($PhaseGroup.winnersTargetPhaseId -ne $null){

                        #Adde die winner target phase id zum objekt
                        Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name WinnerTargetPhase -Value $PhaseGroup.winnersTargetPhaseId

                    }#End of if($PhaseGroup.winnersTargetPhaseId -ne $null)
                    else{

                        #Adde final phase als string für bracket
                        Add-Member -InputObject $NewPhaseGroupObject -MemberType NoteProperty -Name WinnerTargetPhase -Value 'final Phase'
            
                    }#End of else($PhaseGroup.winnersTargetPhaseId -ne $null)

                    #Adde phase group zum phase group array
                    $PhaseGroupArray += $NewPhaseGroupObject
                    }
                }#End of Foreach($PhaseGroup in $EventResponse.entities.groups)

            #Instanzieren von allen gebrauchten arrays
            $PLayerArray= @()
            $SeedArray = @()
            $SetArray = @()
            $StandingsArray = @()

            #Checkt ob die anzahl der phase groups grösser als null ist, falls nicht ist etwas falsch geloffen
            if( $PhaseGroupArray.Count -ge 0 ){
             
                    #Für jede phase group im array
                    Foreach($PhaseGroupInArray in $PhaseGroupArray){

                        #Created denn neuen url für die rest abfrage
                        $PhaseGroupUri = $("https://api.smash.gg/phase_group/" + $PhaseGroupInArray.groupid + "?expand[]=sets&expand[]=entrants&expand[]=standings&expand[]=seeds")
                
                        #Call den rest url 
                        $PhaseGroupResponse = Invoke-RestMethod -Uri $PhaseGroupUri             
                
                        #Für jeden player in der phase group
                        Foreach($Player in $PhaseGroupResponse.entities.player){
                    
                            #Erstelle ein neues powershell objekt für jeden spieler im array
                            $NewPlayerObject = New-Object psobject
                            Add-Member -InputObject $NewPlayerObject -MemberType NoteProperty -Name id -Value $Player.id
                            Add-Member -InputObject $NewPlayerObject -MemberType NoteProperty -Name gamerTag -Value $Player.gamertag
                            Add-Member -InputObject $NewPlayerObject -MemberType NoteProperty -Name country -Value $Player.country
                            Add-Member -InputObject $NewPlayerObject -MemberType NoteProperty -Name entrantId -Value $Player.entrantId

                            #Checken ob der spieler schon im array ist
                            #Dies passiert wenn durch das bracket spieler die schon in pools eingetragen wurden noch einmal eingetragen werden
                            if(-NOT($PLayerArray | Where-Object{$_.id -eq $NewPlayerObject.id })){ 
                        
                                #Füge den spieler zum array hinzu
                                $PlayerArray += $NewPlayerObject
                    
                            }#End of if(-NOT($PLayerArray | Where-Object{$_.id -eq $NewPlayerObject.id }))
                        }

                        Foreach($Seed in $PhaseGroupResponse.entities.seeds){
                            $NewSeedObject = New-Object psobject
                            Add-Member -InputObject $NewSeedObject -MemberType NoteProperty -Name id -Value $Seed.id
                            Add-Member -InputObject $NewSeedObject -MemberType NoteProperty -Name entrantId -Value $Seed.entrantId
                            Add-Member -InputObject $NewSeedObject -MemberType NoteProperty -Name seedNum -Value $Seed.SeedNum
                            Add-Member -InputObject $NewSeedObject -MemberType NoteProperty -Name phaseId -Value $Seed.phaseId

                            $SeedArray += $NewSeedObject
                        }

                        Foreach($Set in $PhaseGroupResponse.entities.sets){
                            $NewSetObject = New-Object psobject
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name id -Value $Set.id
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name phaseGroupId -Value $Set.phaseGroupId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name EventId -Value $Set.EventId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant1Id -Value $Set.Entrant1Id
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant2Id -Value $Set.Entrant2Id
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name WinnerEntrantId -Value $Set.winnerId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name LoserEntrantId -Value $Set.LoserId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant1SeedId -Value $Set.entrant1PrereqId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant2SeedId -Value $Set.entrant2PrereqId
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant1Score -Value $Set.entrant1Score
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Entrant2Score -Value $Set.entrant2Score
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name BestOf -Value $Set.bestOf
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name isGF -Value $Set.isGf
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name Round -Value $Set.displayRound
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name ShortRoundText -Value $Set.ShortRoundText
                            Add-Member -InputObject $NewSetObject -MemberType NoteProperty -Name totalGames -Value $Set.totalGames

                            $SetArray += $NewSetObject
                        }

                        Foreach($Standing in $PhaseGroupResponse.entities.standings){

                            $NewStandingObject = New-Object psobject
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name id -Value $Standing.id
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name entrantId -Value $Standing.entrantId
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name seedId -Value $Standing.SeedId
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name phaseId -Value $Standing.phaseId
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name totalsetsplayed -Value $Standing.totalSetsplayed
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name setsPlayed -Value $Standing.setsPlayed
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name setsWon -Value $Standing.setsWon
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name gamesPlayed -Value $Standing.gamesPlayed
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name gamesWon -Value $Standing.gamesWon
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name placement -Value $Standing.placement
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name losses -Value $Standing.losses
                            Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name destPhaseId -Value $Standing.destPhaseId

                            if( $EventPhase.name -like "*Amateur*"){

                                Add-Member -InputObject $NewStandingObject -MemberType NoteProperty -Name isAmateurBracket -Value $true

                            }

                            $StandingsArray += $NewStandingObject
                        }
                }
            }
        }
        Write-HOst "Breakpoint"

        <#
        $PLayerArray | Export-Csv -Path D:\scripts\ColloseumBasel4\Players.csv -NoTypeInformation
        $StandingsArray | Export-Csv -Path D:\scripts\ColloseumBasel4\Standings.csv -NoTypeInformation
        $SeedArray | Export-Csv -Path D:\scripts\ColloseumBasel4\Seeds.csv -NoTypeInformation
        $PhaseArray | Export-Csv -Path D:\scripts\ColloseumBasel4\Phases.csv -NoTypeInformation
        $PhaseGroupArray | Export-Csv -Path D:\scripts\ColloseumBasel4\PhaseGroups.csv -NoTypeInformation
        $SetArray | Export-Csv -Path D:\scripts\ColloseumBasel4\Sets.csv -NoTypeInformation
        #>

        $StandingsArray | Export-Csv -Path D:\scripts\power9\Standings.csv -NoTypeInformation

        return $StandingsArray, $PLayerArray, $AmateurBracketId
    }
    else{
        Write-Host "event ID is empty, singles was not found in title"
    }
}

Function Get-Losses {
    
    Param(
        [Array]$TournamentInfo,
        [psobject]$PLayerPerformance
    )

    
    $lossesString = $null

    Foreach($loss in $PLayerPerformance.losses ){
                        
        $PlayerHandingTheL = $tournamentInfo | Where-Object -Property entrantId -eq $loss

        if($lossesString -eq $null){

            $lossesString = $playerHandingTheL.gamerTag

        }
        else{

            $lossesString = $($lossesString + ", " + $playerHandingTheL.gamerTag)

        }
    }
    
    return $lossesString

}

#Create Array collecting all the tournament data
$overallarrayOfPlacings = @()
$overallarrayOfLosses = @()

#Go through all tournaments provided
Foreach($tournament in $Tournaments){
    
    $preparedString = $tournament.TournamentLinks.Replace(" ","")

    $tournamentInfo = Query-Tournamentinfo -TournamentLinkString $preparedString

    $TournamentWithPlacings = New-Object PSObject
    $TournamentWithPlacings | add-member Noteproperty "TournamentName" $preparedString  
    
    
    $TournamentWithLosses = New-Object PSObject
    $TournamentWithLosses | add-member Noteproperty "TournamentName" $preparedString                          

    #Go through all players in the player list and search for their placing
    Foreach($player in $playerarray){
        
        #Search for the gamertag in the tournament attendies
        $playerID = $tournamentInfo[1] | Where-Object -Property gamertag -eq $player.PlayerTags 
        $PLayerPLacement = $tournamentInfo[0] | Where-Object -Property entrantID -eq $playerID.entrantId 

        if($PLayerPLacement.count -ge 1){
            Write-Host "test"
        }

        
            
        #Export the placing to the array
        if($PLayerPLacement -ne $null){

            if($PLayerPLacement.phaseId -ne $tournamentInfo[2]){
            
                if($PLayerPLacement.count -ge 1){

                    if($PLayerPLacement[0].destPhaseId -ne $null){

                        $TournamentWithPlacings | add-member Noteproperty $playerID.GamerTag $($PLayerPLacement[0].placement)

                        $lossesString = Get-Losses -TournamentInfo $tournamentInfo[0] -PLayerPerformance $PLayerPLacement

                        $TournamentWithLosses | add-member Noteproperty $playerID.GamerTag $lossesString

                    }
                    else{

                        $TournamentWithPlacings | add-member Noteproperty $playerID.GamerTag $PLayerPLacement[1].placement

                        $lossesString = Get-Losses -TournamentInfo $tournamentInfo[1] -PLayerPerformance $PLayerPLacement

                        $TournamentWithLosses | add-member Noteproperty $playerID.GamerTag $lossesString
                    }
                }
                else{
             
                    $TournamentWithPlacings | add-member Noteproperty $playerID.GamerTag $PLayerPLacement[0].placement

                    $lossesString = Get-Losses -TournamentInfo $tournamentInfo[1] -PLayerPerformance $PLayerPLacement

                    $TournamentWithLosses | add-member Noteproperty $playerID.GamerTag $lossesString
                }            
            }
            else{
           
                $TournamentWithPlacings | add-member Noteproperty $player.PlayerTags "NA"
                $TournamentWithLosses | add-member Noteproperty $player.PlayerTags "NA"    
                       
            }
        }
        else{
            Write-Host "-------------------------------------"
            Write-Host "player placement not found"
            Write-Host $("player in question " + $player.PlayerTags)
            Write-Host "-------------------------------------"

             $TournamentWithPlacings | add-member Noteproperty $player.PlayerTags "NA"
             $TournamentWithLosses | add-member Noteproperty $player.PlayerTags "NA"   
        }
    }

    $overallarrayOfPlacings += $TournamentWithPlacings
    $overallarrayOfLosses += $TournamentWithLosses
    
}

Write-Host $overallarrayOfPlacings
Write-Host $overallarrayOfLosses

$overallarrayOfPlacings | Export-Csv -Path C:\Users\Andi\Desktop\PRResultsPlacements.csv -NoTypeInformation

$overallarrayOfLosses | Export-Csv -Path C:\Users\Andi\Desktop\PRResultsLosses.csv -NoTypeInformation