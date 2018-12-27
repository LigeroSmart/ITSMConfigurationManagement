# --
# Copyright (C) 2001-2018 LIGERO AG, https://ligero.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::ITSMConfigItem::LayoutCustomerCompany;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
    'Kernel::System::CustomerCompany',
);

=head1 NAME

Kernel::Output::HTML::ITSMConfigItem::LayoutCustomerCompany - layout backend module

=head1 DESCRIPTION

All layout functions of customer company objects

=head2 new()

create an object

    $BackendObject = Kernel::Output::HTML::ITSMConfigItem::LayoutCustomerCompany->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=head2 OutputStringCreate()

create output string

    my $Value = $BackendObject->OutputStringCreate(
        Value => 11,       # (optional)
    );

=cut

sub OutputStringCreate {
    my ( $Self, %Param ) = @_;

    # transform ascii to html
    $Param{Value} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Ascii2Html(
        Text           => $Param{Value} || '',
        HTMLResultMode => 1,
    );

    return $Param{Value};
}

=head2 FormDataGet()

get form data as hash reference

    my $FormDataRef = $BackendObject->FormDataGet(
        Key => 'Item::1::Node::3',
        Item => $ItemRef,
    );

=cut

sub FormDataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my %FormData;

    # get form data
    $FormData{Value} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => $Param{Key} );

    # set invalid param
    if ( $Param{Item}->{Input}->{Required} && !$FormData{Value} ) {
        $FormData{Invalid} = 1;
        $Param{Item}->{Form}->{ $Param{Key} }->{Invalid} = 1;
    }

    return \%FormData;
}

=head2 InputCreate()

create a input string

    my $Value = $BackendObject->InputCreate(
        Key   => 'Item::1::Node::3',
        Value => 11,       # (optional)
        Item  => $ItemRef,
    );

=cut

sub InputCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my $SelectedID = $Param{Value} || $Param{Item}->{Input}->{ValueDefault} || '';

    my $CSSClass = 'Modernize';
    my $Required = $Param{Required};
    my $Invalid  = $Param{Invalid};
    my $ItemId   = $Param{ItemId};

    if ($Required) {
        $CSSClass .= ' Validate_Required';
    }

    if ($Invalid) {
        $CSSClass .= ' ServerError';
    }

    # get class list
    my %CompanyList = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyList(
        Limit => 0,    # Display all Customer Companies
    );

    # generate string
    my $String = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->BuildSelection(
        Data         => \%CompanyList,
        Name         => $Param{Key},
        ID           => $ItemId,
        PossibleNone => 1,
        Translation  => 0,
        SelectedID   => $SelectedID,
        Class        => $CSSClass,
    );

    return $String;
}

=head2 SearchFormDataGet()

get search form data

    my $Value = $BackendObject->SearchFormDataGet(
        Key => 'Item::1::Node::3',
        Item => $ItemRef,
    );

=cut

sub SearchFormDataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Key} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Key!',
        );
        return;
    }

    # get form data
    my @Values;
    if ( $Param{Value} ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray( Param => $Param{Key} );
    }

    return \@Values;
}

=head2 SearchInputCreate()

create a search input string

    my $Value = $BackendObject->SearchInputCreate(
        Key => 'Item::1::Node::3',
    );

=cut

sub SearchInputCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    my $Values = $Self->SearchFormDataGet(%Param);

    # get company data
    my %CompanyList = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyList(
        Limit => 0,
    );

    # generate string
    my $String = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->BuildSelection(
        Data        => \%CompanyList,
        Name        => $Param{Key},
        Size        => 5,
        Multiple    => 1,
        Translation => 0,
        SelectedID  => $Values,
        Class       => 'Modernize',
    );

    return $String;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the LIGERO project (L<https://ligero.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
