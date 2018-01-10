use Test::Perl::Critic(-exclude => [
												'RequireFinalReturn',
											   'ProhibitUnusedPrivateSubroutines',
											   'RequireExtendedFormatting',
											   'ProhibitExcessComplexity',
											  ],
							  -severity => 4);
all_critic_ok();
