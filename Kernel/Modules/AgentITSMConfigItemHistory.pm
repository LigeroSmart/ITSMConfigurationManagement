# --
# Copyright (C) 2001-2018 LIGERO AG, https://ligero.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentITSMConfigItemHistory;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $Self->{ConfigItemID} = $ParamObject->GetParam( Param => 'ConfigItemID' );

    # check needed stuff
    if ( !$Self->{ConfigItemID} ) {

        # error page
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Can\'t show history, no ConfigItemID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get neeeded objects
    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');

    # check for access rights
    my $HasAccess = $ConfigItemObject->Permission(
        Scope  => 'Item',
        ItemID => $Self->{ConfigItemID},
        UserID => $Self->{UserID},
        Type   => $ConfigObject->Get("ITSMConfigItem::Frontend::$Self->{Action}")->{Permission},
    );

    if ( !$HasAccess ) {

        # error page
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Can\'t show history, no access rights given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # Define translatable history strings.
    my %HistoryStrings = (
        'CIHistory::ConfigItemCreate'      => Translatable('New ConfigItem (ID=%s)'),
        'CIHistory::VersionCreate'         => Translatable('New version (ID=%s)'),
        'CIHistory::DeploymentStateUpdate' => Translatable('Deployment state updated (new=%s, old=%s)'),
        'CIHistory::IncidentStateUpdate'   => Translatable('Incident state updated (new=%s, old=%s)'),
        'CIHistory::ConfigItemDelete'      => Translatable('ConfigItem (ID=%s) deleted'),
        'CIHistory::LinkAdd'               => Translatable('Link to %s (type=%s) added'),
        'CIHistory::LinkDelete'            => Translatable('Link to %s (type=%s) deleted'),
        'CIHistory::DefinitionUpdate'      => Translatable('ConfigItem definition updated (ID=%s)'),
        'CIHistory::NameUpdate'            => Translatable('Name updated (new=%s, old=%s)'),
        'CIHistory::ValueUpdate'           => Translatable('Attribute %s updated from "%s" to "%s"'),
        'CIHistory::VersionDelete'         => Translatable('Version %s deleted'),
    );

    # get all information about the config item
    my $ConfigItem = $ConfigItemObject->ConfigItemGet(
        ConfigItemID => $Self->{ConfigItemID},
    );
    my $ConfigItemName = $ConfigItem->{Number};

    # get all entries in the history for this config item
    my $Lines = $ConfigItemObject->HistoryGet(
        ConfigItemID => $Self->{ConfigItemID},
    );

    # get shown user info
    my @NewLines = @{$Lines};
    if ( $ConfigObject->Get('ITSMConfigItem::Frontend::HistoryOrder') eq 'reverse' ) {
        @NewLines = reverse @{$Lines};
    }

    # get definition for CI's class
    my $Definition = $ConfigItemObject->DefinitionGet(
        ClassID => $ConfigItem->{ClassID},
    );

    my $Table   = '';
    my $Counter = 1;
    my $Version = 0;
    for my $DataTmp (@NewLines) {
        $Counter++;
        my %Data = (
            %{$DataTmp},
            VersionID => $Version,
        );

        # get general catalog object
        my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

        # trim the comment to only show version number
        if ( $Data{HistoryType} eq 'VersionCreate' ) {
            $Data{Comment} =~ s/\D//g;
            $Data{VersionID} = $Data{Comment};
            $Version = $Data{Comment};
        }
        elsif ( $Data{HistoryType} eq 'ValueUpdate' ) {

            # beautify comment
            my @Parts = split /%%/, $Data{Comment};
            $Parts[0] =~ s{ \A \[.*?\] \{'Version'\} \[.*?\] \{' }{}xms;
            $Parts[0] =~ s{ '\} \[.*?\] \{' }{::}xmsg;
            $Parts[0] =~ s{ '\} \[.*?\] \z }{}xms;

            # get definition info about attribute
            my $AttributeInfo = $ConfigItemObject->DefinitionAttributeInfo(
                Definition    => $Definition->{DefinitionRef},
                AttributePath => $Parts[0],
            );

            if ( $AttributeInfo && $AttributeInfo->{Input}->{Type} eq 'GeneralCatalog' ) {
                my $ItemList = $GeneralCatalogObject->ItemList(
                    Class => $AttributeInfo->{Input}->{Class},
                );

                $Parts[1] = $ItemList->{ $Parts[1] || '' } || '';
                $Parts[2] = $ItemList->{ $Parts[2] || '' } || '';
            }

            # assemble parts
            $Data{Comment} = join '%%', @Parts;
        }
        elsif ( $Data{HistoryType} eq 'DeploymentStateUpdate' ) {

            # get deployment state list
            my $DeplStateList = $GeneralCatalogObject->ItemList(
                Class => 'ITSM::ConfigItem::DeploymentState',
            );

            # show names
            my @Parts = split /%%/, $Data{Comment};
            for my $Part (@Parts) {
                $Part = $DeplStateList->{$Part} || '';
            }

            # assemble parts
            $Data{Comment} = join '%%', @Parts;
        }
        elsif ( $Data{HistoryType} eq 'IncidentStateUpdate' ) {

            # get deployment state list
            my $DeplStateList = $GeneralCatalogObject->ItemList(
                Class => 'ITSM::Core::IncidentState',
            );

            # show names
            my @Parts = split /%%/, $Data{Comment};
            for my $Part (@Parts) {
                $Part = $DeplStateList->{$Part} || '';
            }

            # assemble parts
            $Data{Comment} = join '%%', @Parts;
        }

        # replace text
        if ( $Data{Comment} ) {

            my %Info;

            $Data{Comment} =~ s{ \A %% }{}xmsg;
            my @Values = split /%%/, $Data{Comment};

            $Data{Comment} = $LayoutObject->{LanguageObject}->Translate(
                $HistoryStrings{ 'CIHistory::' . $Data{HistoryType} },
                @Values,
            );

            # remove not needed place holder
            $Data{Comment} =~ s/\%s//g;
        }

        $LayoutObject->Block(
            Name => 'Row',
            Data => {%Data},
        );
    }

    # build page
    my $Output = $LayoutObject->Header(
        Value => $ConfigItemName,
        Type  => 'Small'
    );
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentITSMConfigItemHistory',
        Data         => {
            Name         => $ConfigItemName,
            ConfigItemID => $Self->{ConfigItemID},
            VersionID    => $ParamObject->GetParam( Param => 'VersionID' ),
        },
    );
    $Output .= $LayoutObject->Footer( Type => 'Small' );

    return $Output;
}

1;
